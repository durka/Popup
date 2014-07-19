//
//  FileSystemItem.m
//  Popup
//
//  Created by Alex Burka on 3/2/14.
//
//

#import "FileSystemItem.h"

// from https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/OutlineView/Articles/UsingOutlineDataSource.html#//apple_ref/doc/uid/20000725-BBCDGDAG

@implementation FileSystemItem

static FileSystemItem *rootItem = nil;
static NSMutableArray *leafNode = nil;
static NSString *filter = nil;

+ (void)initialize
{
    if (self == [FileSystemItem class]) {
        leafNode = [[NSMutableArray alloc] init];
    }
}

- (id)initWithPath:(NSString *)path parent:(FileSystemItem *)parentItem
{
    self = [super init];
    if (self) {
        relativePath = [[path lastPathComponent] copy];
        parent = parentItem;
    }
    return self;
}

+ (FileSystemItem *)rootItem
{
    // TODO fix this backwards nesting madness
    // FIXME rootItem is always regenerated as a hack to refresh the tree
    if (true || rootItem == nil) {
        rootItem = [[FileSystemItem alloc]
                        initWithPath:@".password-store"
                        parent:[[FileSystemItem alloc]
                                    initWithPath:@"alex"
                                    parent:[[FileSystemItem alloc]
                                                initWithPath:@"Users"
                                                parent:[[FileSystemItem alloc]
                                                            initWithPath:@"/"
                                                            parent:nil]]]];
    }
    return rootItem;
}

+(void)setFilter:(NSString*)filt
{
    filter = filt;
}

// Creates, caches, and returns the array of children
// Loads children incrementally
- (NSArray *)children
{
    if (children == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *fullPath = [self fullPath];
        BOOL isDir, valid;
        
        valid = [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
        
        if (valid && isDir) {
            NSArray *array = [fileManager
                              contentsOfDirectoryAtPath:fullPath
                              error:NULL];
            NSUInteger numChildren, i;
            numChildren = [array count];
            children = [[NSMutableArray alloc] initWithCapacity:numChildren];
            
            for (i = 0; i < numChildren; i++)
            {
                NSString *subpath = [array objectAtIndex:i];
                if ([subpath characterAtIndex:0] != '.') {
                    FileSystemItem *newChild = [[FileSystemItem alloc]
                                                initWithPath:subpath
                                                parent:self];
                    valid = [fileManager fileExistsAtPath:[newChild fullPath]
                                              isDirectory:&isDir];
                    //printf("checking %s (dir: %d)\n", [[newChild partialPath] UTF8String], isDir);
                    if (filter == nil ||
                        isDir ||
                        [[newChild partialPath]
                         rangeOfString:filter].location != NSNotFound)
                    {
                        if ([newChild numberOfChildren] != 0)
                        {
                            [children addObject:newChild];
                        }
                    }
                }
            }
        } else {
            children = leafNode;
        }
    }
    
    return children;
}

- (NSString *)relativePath
{
    return relativePath;
}

// like fullPath, but stop at rootItem
- (NSString *)partialPath
{
    // if no parent or we reached the root, stop
    if (parent == nil || parent == rootItem) {
        return relativePath;
    }
    
    // recurse up the hierarchy, prepending each parent's path
    return [[parent partialPath] stringByAppendingPathComponent:relativePath];
}

- (NSString *)fullPath
{
    // If no parent, return our own relative path
    if (parent == nil) {
        return relativePath;
    }
    
    // recurse up the hierarchy, prepending each parent’s path
    return [[parent fullPath] stringByAppendingPathComponent:relativePath];
}

- (FileSystemItem *)childAtIndex:(NSUInteger)n
{
    return [[self children] objectAtIndex:n];
}

- (NSInteger)numberOfChildren
{
    NSArray *tmp = [self children];
    return (tmp == leafNode) ? (-1) : [tmp count];
}

@end

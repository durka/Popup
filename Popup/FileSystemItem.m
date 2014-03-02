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
    // TODO fix this madness
    if (rootItem == nil) {
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
            NSArray *array = [fileManager contentsOfDirectoryAtPath:fullPath error:NULL];
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
                    [children addObject:newChild];
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

//
//  FileSystemItem.h
//  Popup
//
//  Created by Alex Burka on 3/2/14.
//
//

@class FileSystemItem;

@interface FileSystemItem : NSObject
{
    NSString *relativePath;
    FileSystemItem *parent;
    NSMutableArray *children;
}

+(FileSystemItem *)rootItem;
+(void)setFilter:(NSRegularExpression*)filt;
+(void)resetLeaves;
+(id)getLeaf;
-(NSInteger)numberOfChildren;// Returns -1 for leaf nodes
-(FileSystemItem *)childAtIndex:(NSUInteger)n; // Invalid to call on leaf nodes
-(NSString *)fullPath;
-(NSString *)partialPath;
-(NSString *)relativePath;

@end

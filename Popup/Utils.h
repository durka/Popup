//
//  Utils.h
//  Popup
//
//  Created by Alex Burka on 5/4/14.
//
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

+(const char*) promptUserFor: (const char*)prompt label:(const char*)label;
+(const char*) promptUserFor: (const char*)prompt label:(const char*)label initial:(const char*)initial;

@end

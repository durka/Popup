//
//  main.m
//  Popup
//
//  Created by Vadim Shpakovski on 7/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "GPGManager.h"

int main(int argc, char *argv[])
{
    printf("hello world!\n");
    
    /*@try
    {
        GPGManager* gm = [[GPGManager alloc] init];
        char *pass = [gm decryptPasswordFromFile:"/Users/alex/.password-store/Web/cloudatcost/aburka1.gpg"];
        printf("The password is %s\n", pass);
        free(pass);
    }
    @catch (NSException *e)
    {
        printf("Error in decryption: %s %s\n", [[e name] UTF8String], [[e reason] UTF8String]);
    }*/
    
    return NSApplicationMain(argc, (const char **)argv);
}

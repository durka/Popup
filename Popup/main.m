//
//  main.m
//  Popup
//
//  Created by Vadim Shpakovski on 7/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
    printf("hello world!\n");
    
    char *newpath;
    asprintf(&newpath, "%s:%s", "/usr/local/bin", getenv("PATH"));
    setenv("PATH", newpath, true);
    free(newpath);
    
    return NSApplicationMain(argc, (const char **)argv);
}

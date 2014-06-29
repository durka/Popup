//
//  Utils.m
//  Popup
//
//  Created by Alex Burka on 5/4/14.
//
//

#import "Utils.h"

@implementation Utils

+(const char*) promptUserFor:(const char *)prompt label:(const char *)label
{
    return [Utils promptUserFor:prompt label:label initial:""];
}

+(const char*) promptUserFor: (const char*)prompt label:(const char*)label initial:(const char *)initial
{
    CFStringRef cf_prompt = CFStringCreateWithCString(kCFAllocatorDefault, prompt, kCFStringEncodingASCII),
                cf_label = CFStringCreateWithCString(kCFAllocatorDefault, label, kCFStringEncodingASCII),
                cf_initial = CFStringCreateWithCString(kCFAllocatorDefault, initial, kCFStringEncodingASCII);
    
    SInt32 err;
    const void *keys[]   = {kCFUserNotificationAlertHeaderKey,
                            kCFUserNotificationAlertMessageKey,
                            kCFUserNotificationTextFieldTitlesKey,
                            kCFUserNotificationTextFieldValuesKey},
               *values[] = {CFSTR("Popup"), cf_prompt, cf_label, cf_initial};
    CFDictionaryRef dict = CFDictionaryCreate(NULL, keys, values, 3, NULL, NULL);
    CFUserNotificationRef dialog = CFUserNotificationCreate(NULL,
                                                            0,
                                                            CFUserNotificationSecureTextField(0),
                                                            &err,
                                                            dict);
    
    CFOptionFlags response;
    CFUserNotificationReceiveResponse(dialog, 0, &response);
    
    CFStringRef result_str = CFUserNotificationGetResponseValue(dialog,
                                                                kCFUserNotificationTextFieldValuesKey,
                                                                0);
    const char *result = CFStringGetCStringPtr(result_str,
                                               CFStringGetFastestEncoding(result_str));
    
    CFRelease(cf_prompt);
    CFRelease(cf_label);
    CFRelease(cf_initial);
    return result;
}

@end

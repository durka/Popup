//
//  GPGManager.h
//  Popup
//
//  Created by Alex Burka on 2/25/14.
//
//

#import <Foundation/Foundation.h>
#include "gpgme.h"

@interface GPGManager : NSObject
{
@private
    gpgme_ctx_t ctx;
    const char* version;
}

+(void) guard:(gpgme_error_t)err what:(const char*)what;
+(int) check:(int)err what:(const char*)what;

-(id) init;
-(void) dealloc;

-(gpgme_error_t) writePassphraseToFile:(int)fd firstTry:(bool)first;
-(char*) decryptPasswordFromFile:(const char*)encrypted_file;

@end

gpgme_error_t passphrase_thunk(void*, const char*, const char*, int, int);

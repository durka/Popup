//
//  GPGManager.m
//  Popup
//
//  Created by Alex Burka on 2/25/14.
//
//

#import <CoreFoundation/CoreFoundation.h>
#import "GPGManager.h"
#import "Utils.h"

@implementation GPGManager

+(void) guard:(gpgme_error_t)err what:(const char*)what
{
    if (err != GPG_ERR_NO_ERROR) {
        [[NSException
            exceptionWithName: @"GPGMEException"
            reason: [NSString
                        stringWithFormat: @"GPG error %s: %s", what, gpgme_strerror(err)]
                        userInfo: nil]
         raise];
    }
}

+(int) check:(int)err what:(const char*)what
{
    if (err == -1) {
        [[NSException
          exceptionWithName: @"GPGMEException"
          reason: [NSString
                   stringWithFormat: @"GPG error %s: %s", what, strerror(errno)]
          userInfo: nil]
         raise];
    }
    return err;
}

-(id) init
{
    if (self = [super init]) {
        version = gpgme_check_version(NULL);
        [GPGManager guard:gpgme_engine_check_version(GPGME_PROTOCOL_OPENPGP) what:"checking engine version"];
    
        [GPGManager guard:gpgme_new(&ctx) what:"creating context:"];
    
        gpgme_set_passphrase_cb(ctx, passphrase_thunk, (__bridge void *)(self));
    }
    
    return self;
}

-(void) dealloc
{
    gpgme_release(ctx);
}

char* sudo(const char *pass)
{
#define kill()                                     \
    {                                              \
        char *tmp = remembered;                    \
        remembered = NULL;                         \
        memset(tmp, 0, strlen(tmp));               \
        free(tmp);                                 \
    }
    
    static char *remembered = NULL;
    static NSTimer *timer = nil;
    const time_t timeout = 600;
    
    char *ret = NULL;
    
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    
    if (pass == NULL) {
        // get old password
        ret = remembered;
    } else {
        // store new password
        if (remembered != NULL) kill();
        remembered = malloc(strlen(pass)+1);
        memset(remembered, 0, strlen(pass)+1);
        strncpy(remembered, pass, strlen(pass));
    }
    
    timer = [NSTimer
             scheduledTimerWithTimeInterval:timeout
             target:[NSBlockOperation blockOperationWithBlock:^{
                printf("end sudo mode\n");
                kill();
             }]
             selector:@selector(main)
             userInfo:nil
             repeats:NO];
    
    return ret;
#undef kill
}

-(gpgme_error_t) writePassphraseToFile:(int)fd firstTry:(bool)first
{
    const char *pass = sudo(NULL);
    if (pass == NULL) {
        pass = [Utils promptUserFor:(first
                                     ? "Enter GPG passphrase"
                                     : "Try again. Enter GPG passphrase")
                      label:"Passphrase"];
        
        // sudo mode
        if (first) sudo(pass);
    }
    
    write(fd, pass, strlen(pass));
    write(fd, "\n", 1);
    
    return 0;
}

-(NSString*) decryptPasswordFromFile:(NSString*)encrypted_file
{
    int fd = -1;
    char *decrypted = NULL;
    
    @try
    {
        fd = [GPGManager check:open([encrypted_file UTF8String], O_RDONLY)
                          what:"Open file"];
        
        gpgme_data_t ciphertext, plaintext;
        [GPGManager guard:gpgme_data_new_from_fd(&ciphertext, fd)
                     what:"creating ciphertext buffer"];
        [GPGManager guard:gpgme_data_new(&plaintext)
                     what:"creating plaintext buffer"];
        
        [GPGManager guard:gpgme_op_decrypt(ctx, ciphertext, plaintext)
                     what:"decrypting password"];
        
        off_t pass_len = [GPGManager check:gpgme_data_seek(plaintext, 0, SEEK_END)
                                      what:"getting length of plaintext buffer"];
        off_t zero     = [GPGManager check:gpgme_data_seek(plaintext, 0, SEEK_SET)
                                      what:"rewinding plaintext buffer"];
        assert(zero == 0);
        
        decrypted = malloc(sizeof(char)*(pass_len+1));
        memset(decrypted, '\0', pass_len+1);
        ssize_t read = [GPGManager check:gpgme_data_read(plaintext, decrypted, pass_len)
                                    what:"reading plaintext buffer"];
        assert(read == pass_len);
        
        NSString *str = [NSString
                            stringWithCString:decrypted
                            encoding:NSASCIIStringEncoding];
        free(decrypted);
        return [str substringToIndex:([str length]-1)];
    }
    @catch (NSException *e)
    {
        if (decrypted) free(decrypted);
        @throw;
    }
    @finally
    {
        if (fd != -1) close(fd);
    }
}

@end

gpgme_error_t passphrase_thunk(void* hook, const char* uid_hint, const char* passphrase_info, int prev_was_bad, int fd)
{
    GPGManager *gm = (__bridge GPGManager*)hook;
    return [gm writePassphraseToFile:fd firstTry:!prev_was_bad];
}


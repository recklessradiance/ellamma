// ellamma/Tweak.mm — v4: In-SpringBoard VoiceServices TTS with AVAudioSession
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>

#define TINYSTORIES_BIN  "/var/root/tinystories/tinystories"
#define MODEL_BIN        "/var/root/tinystories/model.bin"
#define TOKENIZER_BIN    "/var/root/tinystories/tokenizer.bin"
#define ACTIVATOR_NAME   @"com.ellamma.tinystories.activate"

@interface EllammaListener : NSObject <UIAlertViewDelegate>
+ (instancetype)sharedInstance;
@end

@implementation EllammaListener

+ (instancetype)sharedInstance {
    static EllammaListener *s = nil;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [[self alloc] init]; });
    return s;
}

- (NSString *)activator:(id)activator requiresLocalizedTitleForListenerName:(NSString *)name { return @"Ellamma AI"; }
- (NSString *)activator:(id)activator requiresLocalizedDescriptionForListenerName:(NSString *)name { return @"Generate and speak TinyStories LLM output"; }
- (NSString *)activator:(id)activator requiresLocalizedGroupForListenerName:(NSString *)name { return @"AI System"; }
- (NSNumber *)activator:(id)activator requiresIconForListenerName:(NSString *)name scale:(CGFloat)scale { return nil; }

- (NSString *)generateText:(NSString *)prompt {
    NSString *safe = [prompt stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    char cmd[2048];
    snprintf(cmd, sizeof(cmd), "%s %s -z %s -n 80 -i '%s' 2>/dev/null", TINYSTORIES_BIN, MODEL_BIN, TOKENIZER_BIN, [safe UTF8String]);

    FILE *fp = popen(cmd, "r");
    if (!fp) return @"Error: could not run tinystories.";

    NSMutableString *out = [NSMutableString string];
    char buf[512];
    while (fgets(buf, sizeof(buf), fp)) {
        NSString *line = [NSString stringWithUTF8String:buf];
        if (line && ![line hasPrefix:@"achieved tok"]) [out appendString:line];
    }
    pclose(fp);

    NSString *result = [out stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return result.length ? result : @"(no output)";
}

- (void)speakText:(NSString *)text {
    if (!text || text.length == 0) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        // 1. Activate Audio Session inside SpringBoard
        NSError *err = nil;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayback error:&err];
        [session setActive:YES error:&err];

        // 2. Load VoiceServices
        dlopen("/System/Library/PrivateFrameworks/VoiceServices.framework/VoiceServices", RTLD_LAZY);

        Class synthClass = objc_getClass("VSSpeechSynthesizer");
        if (!synthClass) return;

        id synth = [[synthClass alloc] init];

        if ([synth respondsToSelector:@selector(setVolume:)]) {
            ((void(*)(id,SEL,float))objc_msgSend)(synth, @selector(setVolume:), 1.0f);
        }
        if ([synth respondsToSelector:@selector(setRate:)]) {
            ((void(*)(id,SEL,float))objc_msgSend)(synth, @selector(setRate:), 1.0f);
        }


        SEL sel = sel_registerName("startSpeakingString:toURL:withLanguageCode:");
        if ([synth respondsToSelector:sel]) {
            ((id(*)(id,SEL,id,id,id))objc_msgSend)(synth, sel, text, nil, @"en-US");
        }

        // Auto release after speaking estimated time
        float duration = text.length * 0.15f + 2.0f;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [synth release];
        });
    });
}

- (void)activator:(id)activator receiveEvent:(id)event {
    if ([event respondsToSelector:@selector(setHandled:)]) {
        [event performSelector:@selector(setHandled:) withObject:(id)kCFBooleanTrue];
    }

    UIAlertView *alert = [[UIAlertView alloc]
        initWithTitle:@"Ellamma AI"
              message:@"Enter a prompt:"
             delegate:self
    cancelButtonTitle:@"Cancel"
    otherButtonTitles:@"Go", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
    [alert release];
}

- (void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)idx {
    if (idx == 0) return;

    NSString *prompt = [[[alert textFieldAtIndex:0].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] copy];
    if (!prompt.length) { [prompt release]; prompt = [@"Once upon a time" copy]; }

    UIAlertView *hud = [[UIAlertView alloc] initWithTitle:@"Ellamma AI" message:@"Generating\u2026" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [hud show];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *text = [self generateText:prompt];
        [prompt release];

        dispatch_async(dispatch_get_main_queue(), ^{
            [hud dismissWithClickedButtonIndex:0 animated:YES];
            [hud release];

            [self speakText:text];

            UIAlertView *result = [[UIAlertView alloc] initWithTitle:@"Ellamma AI" message:text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [result show];
            [result release];
        });
    });
}

@end

__attribute__((constructor))
static void ellammaInit(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        Class laClass = objc_getClass("LAActivator");
        if (!laClass) return;
        id la = ((id(*)(Class,SEL))objc_msgSend)(laClass, sel_registerName("sharedInstance"));
        if (la) {
            ((void(*)(id,SEL,id,id))objc_msgSend)(la, sel_registerName("registerListener:forName:"), [EllammaListener sharedInstance], ACTIVATOR_NAME);
        }
    });
}

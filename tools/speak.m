// tools/speak.m — Configured Audio Session & Volume TTS
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSString *text = (argc > 1) ? [NSString stringWithUTF8String:argv[1]] : @"Hello from iPhone 4S AI";
        printf("Speaking: %s\n", [text UTF8String]);

        // 1. Initialize Audio Session for Playback
        NSError *err = nil;
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayback error:&err];
        [session setActive:YES error:&err];

        // 2. Load VoiceServices
        void *handle = dlopen("/System/Library/PrivateFrameworks/VoiceServices.framework/VoiceServices", RTLD_LAZY);
        if (!handle) {
            printf("Failed to load VoiceServices framework: %s\n", dlerror());
            return 1;
        }

        Class synthClass = objc_getClass("VSSpeechSynthesizer");
        if (!synthClass) {
            printf("VSSpeechSynthesizer class not found\n");
            return 1;
        }

        id synth = [[synthClass alloc] init];

        // 3. Set volume and rate
        if ([synth respondsToSelector:@selector(setVolume:)]) {
            ((void(*)(id,SEL,float))objc_msgSend)(synth, @selector(setVolume:), 1.0f);
        }
        if ([synth respondsToSelector:@selector(setRate:)]) {
            ((void(*)(id,SEL,float))objc_msgSend)(synth, @selector(setRate:), 0.5f);
        }

        // 4. Start speaking with explicit language code
        SEL sel = sel_registerName("startSpeakingString:toURL:withLanguageCode:");
        if ([synth respondsToSelector:sel]) {
            printf("Synthesizing audio...\n");
            ((id(*)(id,SEL,id,id,id))objc_msgSend)(synth, sel, text, nil, @"en-US");
        }

        // Sleep to let audio play through speaker
        float duration = text.length * 0.15f + 2.0f;
        usleep((useconds_t)(duration * 1000000));

        printf("Finished.\n");
        [synth release];
    }
    return 0;
}

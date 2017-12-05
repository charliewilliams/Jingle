//
//  CWAudioHandler.m
//  CWShaker
//
//  Created by C Williams on 02/11/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioUnit/AudioComponent.h>
#import <AudioUnit/AudioUnitProperties.h>
#import <Crashlytics/Crashlytics.h>
#import "CWAudioHandler.h"
#import "CWInstrumentFactory.h"
#import "iSTK.h"
#import "iSTK/iSTK.h"
#import "CWInstrument.h"
#import "MotionTracker.h"

#define kAudioRestartDelay 0.1
#define kSampleRate 44100.0f
#define kFrameSize 512
#define kNumChannels 2 // gotta be 2 for some reason

#define Check(expr) do { OSStatus err = (expr); if (err) { NSLog(@"error %d from %s", (int)err, #expr); NSAssert(0, nil); exit(1); } } while (0)
#define NSCheck(expr) do { NSError *err = nil; if (!(expr)) { NSLog(@"error from %s: %@", #expr, err); NSAssert(0, nil); exit(1); } } while (0)

static stk::Instrmnt *instrument;
static InstrumentData data;

void audioCallback(Float32 *buffer, UInt32 framesize, void *userData) {
    
    if (!instrument) {
        
        memset(buffer, 0, framesize * 2 * sizeof(int));
        return;
    }
    
    for (int i=0; i<framesize; i++) {
        
        SAMPLE out = instrument->tick();
        buffer[2*i] = buffer[2*i+1] = out;
    }
}

void accelerometerCallback(AccelerometerData *accelData) {
    
    if (!accelData || !instrument || !data.baseNote) {
        return;
    }
    
    NSUInteger baseNote = data.baseNote;
    CGFloat amplitude = accelData->magnitude * INT16_MAX;

//    if (amplitude > minShakeAmplitude && !playingNote) {
//
//        playingNote = YES;
//        [Answers logContentViewWithName:@"Shake" contentType:nil contentId:nil customAttributes:nil];
//
//    } else if (amplitude < resetThreshold && playingNote) {
//        playingNote = NO;
//    }

//    if (baseNote == 196 && (accelData->axis == y || accelData->axis == z)) { // egg shaker
//        return;
//    }
    instrument->noteOn(baseNote, amplitude);
}

@interface CWAudioHandler () {
    
    HostCallbackInfo *callBackInfo;
}

@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) BOOL outputAudioUnitIsPublished;
@property (nonatomic, assign) BOOL isSetup;

@end

@implementation CWAudioHandler

static CWAudioHandler *sharedHandler;

+ (id)alloc {
    NSAssert(sharedHandler==nil, nil);
    return [super alloc];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionMediaServicesWereResetNotification object:nil];
}

+ (CWAudioHandler *)sharedHandler {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHandler = [[CWAudioHandler alloc] init];
    });
    return sharedHandler;
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionMediaServicesWereResetNotification object:nil queue:nil usingBlock: ^(NSNotification *note) {
            
            [self stop];
            [self start];
        }];
    }
    return self;
}

- (void)start {

    NSError *error = nil;
    [[AVAudioSession sharedInstance] setActive:YES error:&error];

    if (!self.isSetup) {

        stk::Stk::setSampleRate(kSampleRate);
        stk::Stk::showWarnings(true);

        data = {};

        if (!MoAudio::init(kSampleRate, kFrameSize, kNumChannels) || !MoAudio::start(audioCallback, &data)) {
            DLog(@"Couldn't init/start MoAudio");
            exit(1);
        };

        if (!self.outputAudioUnitIsPublished) {
            [self publishOutputAudioUnit];
        }

        instrument = new stk::Shakers();

        self.isSetup = YES;
    }

}

- (void)stop {

    NSError *error = nil;
    [[AVAudioSession sharedInstance] setActive:NO error:&error];

    if (error) {
        DLog(@"%@", error);
    }

    MoAudio::stop();
    MoAudio::shutdown();

    self.isSetup = NO;
}

- (void)accelerometerDidUpdateWithData:(AccelerometerData *)accelData {
    
    accelerometerCallback(accelData);
}

- (void)setActiveInstrument:(CWInstrument *)newInstrument {
    
    InstrumentData *inst = newInstrument.instPtr;
    
    if (!inst) {
        return;
    }
    
    data.range = inst->range;
    data.baseNote = inst->baseNote;
    data.amplitude = inst->amplitude;
}

- (void)playExampleSoundForInstrument:(CWInstrument *)inInstrument {
    
    if (!inInstrument) {
        return;
    }
    [self setActiveInstrument:inInstrument];
    instrument->noteOn(inInstrument.instPtr->baseNote, 1);
}

#pragma mark - Audio session stuff

- (void)audioSessionDidChangeInterruptionType:(NSNotification *)notification {
    
    AVAudioSessionInterruptionType interruptionType = (AVAudioSessionInterruptionType)[[[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    
    if (interruptionType == AVAudioSessionInterruptionTypeBegan) {
        
        AudioOutputUnitStop( MoAudio::m_au );
    }
    else if (interruptionType == AVAudioSessionInterruptionTypeEnded) {
        
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setActive:YES error:&error];

        if (error) {
            DLog(@"%@", error);
        }
        AudioOutputUnitStart( MoAudio::m_au );
    }
}

- (void)audioSessionDidChangeRoute:(NSNotification *)notification {
    
    if (!MoAudio::m_au) {
        return;
    }

    // if there was a route change, we need to dispose the current rio unit and create a new one
    Check(AudioComponentInstanceDispose( MoAudio::m_au ));

    MoAudio::stop();
    MoAudio::shutdown();

    double delayInSeconds = kAudioRestartDelay;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        CGFloat sampleRate = [audioSession sampleRate];
        if (!sampleRate || sampleRate < 0) return;
        MoAudio::init(sampleRate, kFrameSize, kNumChannels);

        MoAudio::checkInput();

        Check(AudioOutputUnitStart( MoAudio::m_au ));
    });
}

//- (void)setAudioSessionActive {
//    AVAudioSession *session = [AVAudioSession sharedInstance];
//    NSCheck([session setPreferredSampleRate:kSampleRate error:&err]);
//    NSCheck([session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&err]);
//    NSCheck([session setActive:YES error:&err]);
//}
//
//- (void)setAudioSessionInactive {
//    AVAudioSession *session = [AVAudioSession sharedInstance];
//    NSCheck([session setActive:NO error:&err]);
//}

#pragma mark - Inter-App Audio

- (NSURL *)audioHostURL {
    
    if (!MoAudio::m_au) {
        return nil;
    }
    
    CFURLRef instrumentUrl;
    UInt32 dataSize = sizeof(instrumentUrl);
    OSStatus result = AudioUnitGetProperty(MoAudio::m_au, kAudioUnitProperty_PeerURL, kAudioUnitScope_Global, 0, &instrumentUrl, &dataSize);
    
    if (result == noErr) {
        
        return (__bridge NSURL*)instrumentUrl;
    }
    return nil;
}

- (void)getHostCallBackInfo {
    
    if (!MoAudio::m_au) {
        return;
    }
    
    [self stop];
    
    UInt32 dataSize = sizeof(HostCallbackInfo);
    callBackInfo = (HostCallbackInfo *)malloc(dataSize);
    OSStatus result = AudioUnitGetProperty(MoAudio::m_au, kAudioUnitProperty_HostCallbacks, kAudioUnitScope_Global, 0, callBackInfo, &dataSize);
    
    if (result != noErr) {
        NSLog(@"Error occured fetching kAudioUnitProperty_HostCallbacks : %d", (int)result);
        free(callBackInfo);
        callBackInfo = NULL;
    }
    
    [self start];
}

- (BOOL)isHostConnected {
    
    if (!MoAudio::m_au) {
        return NO;
    }
    
    UInt32 connect;
    UInt32 dataSize = sizeof(UInt32);
    Check(AudioUnitGetProperty(MoAudio::m_au, kAudioUnitProperty_IsInterAppConnected, kAudioUnitScope_Global, 0, &connect, &dataSize));
    if ((BOOL)connect != self.connected) {
        
        self.connected = connect;

        if (self.connected) {
            
            [self stop];
            [self start];

            [self getHostCallBackInfo];
//            [self sendStateToRemoteHost:kAudioOutputUnitProperty_RemoteControlToHost];
            
        } else {
            
            [self stop];
            [self start];
        }
    }
    return self.connected;
}

- (void)publishOutputAudioUnit {

    // TODO make this work
    AudioComponentDescription desc = { kAudioUnitType_RemoteGenerator, 'shkr', 'cwcw', 0, 0 };
    OSStatus status = AudioOutputUnitPublish(&desc, CFSTR("Jingle app"), 1, MoAudio::m_au);

    if (status) {
        DLog(@"Couldn't publish audio unit");
    } else {
        [self addAudioUnitPropertyListener];
        self.outputAudioUnitIsPublished = YES;
    }
}

- (void)addAudioUnitPropertyListener {
    
    AudioUnitRemovePropertyListenerWithUserData(MoAudio::m_au, kAudioUnitProperty_IsInterAppConnected, AudioUnitPropertyChangeDispatcher, (__bridge void *)(self));
    AudioUnitRemovePropertyListenerWithUserData(MoAudio::m_au, kAudioOutputUnitProperty_HostTransportState, AudioUnitPropertyChangeDispatcher, (__bridge void *)(self));
    
    AudioUnitAddPropertyListener(MoAudio::m_au, kAudioUnitProperty_IsInterAppConnected, AudioUnitPropertyChangeDispatcher, (__bridge void *)(self));
    AudioUnitAddPropertyListener(MoAudio::m_au, kAudioOutputUnitProperty_HostTransportState, AudioUnitPropertyChangeDispatcher, (__bridge void *)(self));
}

void AudioUnitPropertyChangeDispatcher(void *inRefCon, AudioUnit inUnit, AudioUnitPropertyID inID, AudioUnitScope inScope, AudioUnitElement inElement) {
    CWAudioHandler *SELF = (__bridge CWAudioHandler *)inRefCon;
    [SELF audioUnitPropertyChangedListener:inRefCon unit:inUnit propID:inID scope:inScope element:inElement];
}

- (void)audioUnitPropertyChangedListener:(void *)inObject unit:(AudioUnit)inUnit propID:(AudioUnitPropertyID)inID scope:(AudioUnitScope)inScope element:(AudioUnitElement)inElement {
    if (inID == kAudioUnitProperty_IsInterAppConnected) {
        [self isHostConnected];
    }
}

- (void)sendStateToRemoteHost:(AudioUnitRemoteControlEvent) state {
    if (MoAudio::m_au) {
        UInt32 controlEvent = state;
        UInt32 dataSize = sizeof(controlEvent);
        Check(AudioUnitSetProperty(MoAudio::m_au, kAudioOutputUnitProperty_RemoteControlToHost, kAudioUnitScope_Global, 0, &controlEvent, dataSize));
    }
}

#pragma mark - Properties

- (NSUserDefaults *)store {
    return [NSUserDefaults standardUserDefaults];
}

@end

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
    
    if (instrument) {
        instrument->noteOn(inInstrument.instPtr->baseNote, 1);
    }
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

#pragma mark - Properties

- (NSUserDefaults *)store {
    return [NSUserDefaults standardUserDefaults];
}

@end

//
//  CWAudioHandler.h
//  CWShaker
//
//  Created by C Williams on 02/11/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

#import "MotionTracker.h"

struct InstrumentData {
    NSUInteger baseNote;
    NSUInteger range;
    CGFloat amplitude;
    NSUInteger decay;
};

@class CWInstrument;

@interface CWAudioHandler : NSObject

@property (nonatomic, readonly) NSURL *audioHostURL;

+ (CWAudioHandler *)sharedHandler;
- (void)start;
- (void)stop;
- (void)setActiveInstrument:(CWInstrument *)newInstrument;
- (void)playExampleSoundForInstrument:(CWInstrument *)instrument;
- (void)accelerometerDidUpdateWithData:(struct AccelerometerData *)data;
- (void)audioSessionDidChangeInterruptionType:(NSNotification *)notification;
- (void)audioSessionDidChangeRoute:(NSNotification *)notification;

@end

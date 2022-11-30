//
//  CWAudioHandler.h
//  CWShaker
//
//  Created by C Williams on 02/11/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

//@import Foundation;
#import "MotionTracker.h"

struct InstrumentData {
    NSUInteger baseNote;
    NSUInteger range;
    CGFloat amplitude;
    NSUInteger decay;
};

@class CWInstrument;

@interface CWAudioHandler : NSObject

@property (nonatomic, readonly, nonnull) NSURL *audioHostURL;

+ (nonnull CWAudioHandler *)sharedHandler;
- (void)start;
- (void)stop;
- (void)setActiveInstrument:(nonnull CWInstrument *)newInstrument;
- (void)playExampleSoundForInstrument:(nonnull CWInstrument *)instrument;
- (void)accelerometerDidUpdateWithData:(nonnull struct AccelerometerData *)data;
- (void)audioSessionDidChangeInterruptionType:(nonnull NSNotification *)notification;
- (void)audioSessionDidChangeRoute:(nonnull NSNotification *)notification;

@end

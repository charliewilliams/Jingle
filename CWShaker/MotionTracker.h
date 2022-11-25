//
//  MotionTracker.h
//  CWShaker
//
//  Created by Charlie Williams on 12/07/2013.
//  Copyright (c) 2013 C Williams. All rights reserved.
//

@import Foundation;
//@import CoreMotion;
@import UIKit;

typedef enum Axis {
    none = -1,
    x,
    y,
    z
} Axis;

typedef enum Direction {
    decreasing = -1,
    zero,
    increasing
} Direction;

struct AccelerometerData {
    CGFloat magnitude;
    Axis axis;
    Direction direction;
};

#define kUpdateFrequency 1/60.0
#define kMinMagnitude 0.
#define kAccelQueueName "com.shaker.accelQueue"
#define kMinZeroDebounce 0.0001

@class AudioDeviceManager;
@class AccelerometerFilter;

#if TARGET_OS_IOS
@interface MotionTracker : NSObject <UIAccelerometerDelegate>

#elif TARGET_OS_TV
#import <GameController/GameController.h>
@interface MotionTracker : NSObject

#endif
{
    AccelerometerFilter *filter;
    struct AccelerometerData data;
    CGFloat lastValues[3];
    Direction zeroCrossed[3];
}

@property (nonatomic, strong) AudioDeviceManager *audioManager;

+ (MotionTracker *)sharedTracker;
- (void)start;
- (void)stop;

@end

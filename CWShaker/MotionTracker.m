//
//  MotionTracker.m
//  CWShaker
//
//  Created by Charlie Williams on 12/07/2013.
//  Copyright (c) 2013 C Williams. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import "MotionTracker.h"
#import "AccelerometerFilter.h"
#import "CWAudioHandler.h"

@interface MotionTracker ()

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSOperationQueue *accelQueue;

@end

@implementation MotionTracker

- (void)dealloc {
    
    [self stop];
}

+ (MotionTracker *)sharedTracker {
    
    static MotionTracker *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MotionTracker alloc] init];
    });
    
    return sharedInstance;
}

- (id)init {
    
    if (self = [super init]) {
        
        [self changeFilter:[HighpassFilter class]];
        
        self.accelQueue = [[NSOperationQueue alloc] init];
        lastValues[0] = lastValues[1] = lastValues[2] = 0;
        zeroCrossed[0] = zeroCrossed[1] = zeroCrossed[2] = NO;
    }
    return self;
}

- (void)stop {
    
    // Don't lazy-load if we've killed it already
    [_motionManager stopAccelerometerUpdates];
}

- (void)start {
    
    if (self.motionManager.isAccelerometerActive) {
        return;
    }
    
    [self.motionManager startAccelerometerUpdatesToQueue:self.accelQueue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        
        [filter addAcceleration:accelerometerData.acceleration];
        
        [self updateZeroCrossingWithX:filter.x y:filter.y z:filter.z];
        
        Axis eventAxis = [self findDirectionChangeWithX:filter.x y:filter.y z:filter.z];
        
        data.axis = eventAxis;
        data.magnitude = [self magnitudeOfX:filter.x y:filter.y z:filter.z];
        data.direction = [self absMaxOfX:filter.x y:filter.y z:filter.z] > 0;
        
        [[CWAudioHandler sharedHandler] accelerometerDidUpdateWithData:&data];
        
        lastValues[0] = filter.x;
        lastValues[1] = filter.y;
        lastValues[2] = filter.z;
    }];
}

- (void)updateZeroCrossingWithX:(CGFloat)inx y:(CGFloat)iny z:(CGFloat)inz {
    
    if (inx > 0 && lastValues[x] <= 0) {
        zeroCrossed[x] = increasing;
    } else if (inx < 0 && lastValues[x] >= 0) {
        zeroCrossed[x] = decreasing;
    }
    if (iny > 0 && lastValues[y] <= 0) {
        zeroCrossed[y] = increasing;
    } else if (iny < 0 && lastValues[y] >= 0) {
        zeroCrossed[y] = decreasing;
    }
    if (inz > 0 && lastValues[z] <= 0) {
        zeroCrossed[z] = increasing;
    } else if (inz < 0 && lastValues[z] >= 0) {
        zeroCrossed[z] = decreasing;
    }
}

- (Axis)findDirectionChangeWithX:(CGFloat)inx y:(CGFloat)iny z:(CGFloat)inz {
 
    if ((zeroCrossed[x] == increasing && inx < lastValues[x]) || (zeroCrossed[x] == decreasing && inx > lastValues[x])) {
        zeroCrossed[x] = NO;
        return x;
    }
    if ((zeroCrossed[y] == increasing && iny < lastValues[y]) || (zeroCrossed[y] == decreasing && iny > lastValues[y])) {
        zeroCrossed[y] = NO;
        return y;
    }
    if ((zeroCrossed[z] == increasing && inz < lastValues[z]) || (zeroCrossed[z] == decreasing && inz > lastValues[z])) {
        zeroCrossed[z] = NO;
        return z;
    }
    return none;
}

- (CGFloat)magnitudeOfX:(CGFloat)x y:(CGFloat)y z:(CGFloat)z {
    
    return pow(x, 2) + pow(y, 2) + pow(z, 2);
}

- (CGFloat)absMaxOfX:(CGFloat)x y:(CGFloat)y z:(CGFloat)z {
    
    CGFloat absx = fabs(x);
    CGFloat absy = fabs(y);
    CGFloat absz = fabs(z);
    
    if (absx >= absy && absx >= absz) {
        return x;
    }
    if (absy >= absx && absy >= absz) {
        return y;
    }
    if (absz >= absx && absz >= absy) {
        return z;
    }
    NSAssert(0, @"shouldn't get here");
    return 0;
}

-(void)changeFilter:(Class)filterClass {
    
    if(filterClass != [filter class]) {
        
        filter = [[filterClass alloc] initWithSampleRate:kUpdateFrequency cutoffFrequency:5.0];
    }
}

#pragma mark - Properties

- (CMMotionManager *)motionManager {
    
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
        [_motionManager setAccelerometerUpdateInterval:kUpdateFrequency];
        [_motionManager setDeviceMotionUpdateInterval:kUpdateFrequency];
    }
    return _motionManager;
}

@end

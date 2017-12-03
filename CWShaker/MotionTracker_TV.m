//
//  MotionTracker.m
//  CWShaker
//
//  Created by Charlie Williams on 12/07/2013.
//  Copyright (c) 2013 C Williams. All rights reserved.
//

#import "AccelerometerFilter.h"

@import GameController;
// redefine CMAcceleration
//typedef GCAcceleration CMAcceleration;

#import "MotionTracker.h"
#import "CWAudioHandler.h"

@interface MotionTracker ()

@property (nonatomic, strong) GCController *controller;
@property (nonatomic, strong) NSOperationQueue *accelQueue;
@property (atomic, assign) BOOL running;

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
        
        [[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidConnectNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
           
            GCController *controller = note.object;
            if (controller.motion) {
                
                sharedInstance.controller = controller;
                [GCController stopWirelessControllerDiscovery];
            }
        }];
        
        [GCController startWirelessControllerDiscoveryWithCompletionHandler:^{
            
            for (GCController *controller in [GCController controllers]) {
                
                if (controller.motion) {
                    sharedInstance.controller = controller;
                    break;
                }
            }
        }];
        
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
    // No-op
}

- (void)start {
    
    if (self.running) {
        return;
    }
    
    self.running = YES;
}

- (void)setController:(GCController *)controller {
    
    _controller = controller;
    
    __weak MotionTracker *weakSelf = self;
    controller.motion.valueChangedHandler = ^(GCMotion *motion) {
        
        MotionTracker *SELF = weakSelf;
        AccelerometerFilter *_filter = SELF->filter;
        CMAcceleration accel;
        accel.x = motion.userAcceleration.x;
        accel.y = motion.userAcceleration.y;
        accel.z = motion.userAcceleration.z;
        [_filter addAcceleration:accel];
        
        [SELF updateZeroCrossingWithX:_filter.x y:_filter.y z:_filter.z];
        
        Axis eventAxis = [SELF findDirectionChangeWithX:_filter.x y:_filter.y z:_filter.z];
        
        data.axis = eventAxis;
        data.magnitude = [weakSelf magnitudeOfX:_filter.x y:_filter.y z:_filter.z];
        data.direction = [weakSelf absMaxOfX:_filter.x y:_filter.y z:_filter.z] > 0;
        
        struct AccelerometerData d = SELF->data;
        [[CWAudioHandler sharedHandler] accelerometerDidUpdateWithData:&d];
        
        lastValues[0] = _filter.x;
        lastValues[1] = _filter.y;
        lastValues[2] = _filter.z;
    };
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

- (void)changeFilter:(Class)filterClass {
    
    if(filterClass != [filter class]) {
        
        filter = [[filterClass alloc] initWithSampleRate:kUpdateFrequency cutoffFrequency:5.0];
    }
}

@end

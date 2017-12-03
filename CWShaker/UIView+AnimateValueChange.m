//
//  UIView+AnimateValueChange.m
//  CWTTT3Game
//
//  Created by C Williams on 02/06/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

#import "UIView+AnimateValueChange.h"

#define kDefaultDuration 0.3
#define kPulseAnimationKey @"kPulseAnimationKey"
#define kPulseAnimationKeyScale @"kPulseAnimationKeyScale"

@implementation UIView (AnimateValueChange)

- (void)cycleWithDuration:(CGFloat)duration midpointBlock:(dispatch_block_t)block completion:(dispatch_block_t)completion {
    
    [self animateDownWithDuration:duration completion:^{
        block();
        [self animateUpWithDuration:duration completion:^{
            completion();
        }];
    }];
}

- (void)cycleWithDuration:(CGFloat)duration midpointBlock:(dispatch_block_t)block {
    
    [self animateDownWithDuration:duration completion:^{
        block();
        [self animateUpWithDuration:duration completion:nil];
    }];
}

- (void)cycleWithMidpointBlock:(dispatch_block_t)block completion:(dispatch_block_t)completion {
    
    [self animateDownWithDuration:kDefaultDuration completion:^{
        block();
        [self animateUpWithDuration:kDefaultDuration completion:^{
            completion();
        }];
    }];
}

- (void)cycleWithMidpointBlock:(dispatch_block_t)block {
    
    [self animateDownWithDuration:kDefaultDuration completion:^{
        block();
        [self animateUpWithDuration:kDefaultDuration completion:nil];
    }];
}
- (void)animateDownWithDuration:(CGFloat)duration completion:(dispatch_block_t)completion {
    
    [UIView animateWithDuration:duration animations:^{
        self.alpha = 0.0f;
    } completion:^(BOOL finished) {
        if (completion) completion();
    }];
}

- (void)animateUpWithDuration:(CGFloat)duration completion:(dispatch_block_t)completion {
    
    [UIView animateWithDuration:duration animations:^{
        self.alpha = 1.0f;
    } completion:^(BOOL finished) {
        if (completion) completion();
    }];
}

#pragma mark - Pulse


- (void)pulse {
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.duration = 0.6;
    animation.repeatCount = HUGE_VALF;
    animation.autoreverses = YES;
    animation.fromValue = @(1.0);
    animation.toValue = @(0.8);
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    [self.layer addAnimation:animation forKey:kPulseAnimationKey];
    
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.duration = 1.2;
    scale.repeatCount = HUGE_VALF;
    scale.autoreverses = YES;
    scale.toValue = @(1.02);
    scale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.layer addAnimation:scale forKey:kPulseAnimationKeyScale];
}

- (void)stopPulsing {
    
    CAAnimation *animation = [self.layer animationForKey:kPulseAnimationKey];
    if (!animation) return;
    
    CABasicAnimation *lastTime = [CABasicAnimation animationWithKeyPath:@"opacity"];
    lastTime.duration = 2.0;
    lastTime.toValue = @(1.0);
    [self.layer addAnimation:lastTime forKey:kPulseAnimationKey];
    
    CAAnimation *scale = [self.layer animationForKey:kPulseAnimationKeyScale];
    if (!scale) return;
    
    CABasicAnimation *lastTimeScale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    lastTimeScale.duration = 2.0;
    lastTimeScale.toValue = @(1.0);
    [self.layer addAnimation:lastTimeScale forKey:kPulseAnimationKeyScale];
}

@end

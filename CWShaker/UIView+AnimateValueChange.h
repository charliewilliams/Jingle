//
//  UIView+AnimateValueChange.h
//  CWTTT3Game
//
//  Created by C Williams on 02/06/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (AnimateValueChange)

- (void)cycleWithMidpointBlock:(dispatch_block_t)block;
- (void)cycleWithDuration:(CGFloat)duration midpointBlock:(dispatch_block_t)block;
- (void)cycleWithMidpointBlock:(dispatch_block_t)block completion:(dispatch_block_t)completion;
- (void)cycleWithDuration:(CGFloat)duration midpointBlock:(dispatch_block_t)block completion:(dispatch_block_t)completion;

- (void)pulse;
- (void)stopPulsing;

@end

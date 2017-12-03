//
//  CWRadialGradientView.m
//

#import "CWRadialGradientView.h"

#define kStartingRadiusFactor 0.032f

@implementation CWRadialGradientView

- (void)drawRect:(CGRect)rect {

    CGPoint c = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    // Drawing code
    CGContextRef cx = UIGraphicsGetCurrentContext();
    
    if (cx) {
        CGContextSaveGState(cx);
    }
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    
    CGFloat comps[] = {0.0,0.0,0.0,0.0,
                       0.0,0.0,0.0,1.0};
    
    CGFloat locs[] = {0,1};
    CGGradientRef g = CGGradientCreateWithColorComponents(space, comps, locs, 2);
    
    CGContextDrawRadialGradient(cx, g, c, rect.size.width * kStartingRadiusFactor, c, rect.size.width * 1.05, 0);
    
    if (cx) {
        CGContextRestoreGState(cx);
    }
    
    CGGradientRelease(g);
    CGColorSpaceRelease(space);
}

@end

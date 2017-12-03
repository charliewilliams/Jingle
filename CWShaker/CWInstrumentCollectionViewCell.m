//
//  CWInstrumentCollectionViewCell.m
//  CWShaker
//
//  Created by C Williams on 02/11/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

#import "CWInstrumentCollectionViewCell.h"
#import "CWInstrument.h"
#import "CWRadialGradientView.h"
#import "UIView+AnimateValueChange.h"

#define kPulseAnimationKey @"kPulseAnimationKey"
#define kDefaultBorderWidth 2.0
#define kTouchScaleMomentary 1.19
#define kTouchScaleLocked 1.1

@interface CWInstrumentCollectionViewCell ()

@property (nonatomic, strong) CWInstrument *instrument;

@end

@implementation CWInstrumentCollectionViewCell

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    [self.instrumentImageView addConstraint:[NSLayoutConstraint constraintWithItem:self.instrumentImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.instrumentImageView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
}

- (void)configureWithInstrument:(CWInstrument *)instrument {
    
    NSAssert(instrument != nil, @"need an instrument here");
    
    [self.titleLabel setText:instrument.name];
    self.accessibilityLabel = instrument.name;
    
    self.instrumentImageView.image = instrument.image;
    self.instrumentImageView.layer.cornerRadius = self.instrumentImageView.bounds.size.width/2.;
    self.instrumentImageView.layer.borderColor = self.isSelected ? [self selectedColor].CGColor : [self unselectedColor].CGColor;
    self.instrumentImageView.layer.borderWidth = kDefaultBorderWidth;
    
    self.mainContentView.layer.shadowColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
    self.mainContentView.layer.shadowOffset = CGSizeMake(0, 2);
    self.mainContentView.layer.shadowOpacity = 0.3;
    self.mainContentView.layer.shadowRadius = 10;
    
    self.instrument = instrument;
}

- (void)setSelected:(BOOL)selected {

    [super setSelected:selected];

    self.instrumentImageView.layer.borderColor = selected ? [self selectedColor].CGColor : [self unselectedColor].CGColor;
    self.instrumentImageView.layer.shadowRadius = selected ? 20 : 10;
    self.mainContentView.layer.shadowOpacity = selected ? 0.6 : 0.3;
}

- (void)pulseBuyText {
    
    [UIView animateWithDuration:0.1 animations:^{
        
        self.titleLabel.transform = CGAffineTransformMakeScale(kTouchScaleLocked, kTouchScaleLocked);
        self.scrollLockIndicatorLabel.transform = CGAffineTransformMakeScale(kTouchScaleLocked, kTouchScaleLocked);
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.3 animations:^{
            
            self.titleLabel.transform = CGAffineTransformIdentity;
            self.scrollLockIndicatorLabel.transform = CGAffineTransformIdentity;
        }];
    }];
}

#pragma mark - Colors

- (UIColor *)selectedColor {
    return [UIColor whiteColor];
}

- (UIColor *)unselectedColor {
    return [UIColor colorWithWhite:1.0 alpha:0.2];
}

@end

//
//  CWInstrumentCollectionViewCell.h
//  CWShaker
//
//  Created by C Williams on 02/11/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

@class CWInstrument;
@class CWRadialGradientView;

@interface CWInstrumentCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *mainContentView;
@property (weak, nonatomic) IBOutlet UIImageView *instrumentImageView;
@property (nonatomic, readonly) CWInstrument *instrument;
@property (weak, nonatomic) IBOutlet UILabel *scrollLockIndicatorLabel;
@property (nonatomic, assign) BOOL isSelectedInstrument;

- (void)configureWithInstrument:(CWInstrument *)instrument;
- (void)pulseBuyText;

@end

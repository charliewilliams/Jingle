//
//  CWMainCollectionViewLayout.m
//  CWShaker
//
//  Created by C Williams on 18/11/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

#import "CWMainCollectionViewFlowLayout.h"
#import "CWInstrumentCollectionViewCell.h"

@implementation CWMainCollectionViewFlowLayout
    
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    
    CGPoint point = [super targetContentOffsetForProposedContentOffset:proposedContentOffset withScrollingVelocity:velocity];
    
    CGFloat cellWidth = self.cellWidth;
    NSInteger screenNumber = (point.x + cellWidth/2.) / cellWidth;
    CGFloat xOffset = screenNumber * cellWidth - self.sectionInset.left;
    
    if (isPad) {
        xOffset = screenNumber * 512 - 370;
    }
    
    return CGPointMake(xOffset, point.y);
}

- (CGFloat)cellWidth {
    
    if (isPad) {
        return 512;
    }
    
    static CGFloat cellWidth = 0;
    
    if (!cellWidth) {
        UICollectionViewCell *cell = [[self collectionView] cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        cellWidth = cell.bounds.size.width;
    }

    return cellWidth;
}

@end

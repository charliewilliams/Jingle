//
//  CWViewController.m
//  CWShaker
//
//  Created by C Williams on 02/11/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

@import AVFoundation;
#import "CWMainCollectionViewController.h"
#import "CWInstrumentCollectionViewCell.h"
#import "CWInstrumentFactory.h"
#import "MotionTracker.h"
#import "CWAudioHandler.h"
#import "UIView+AnimateValueChange.h"
#import "UIView+Glow.h"
#import "CWInstrument.h"
#import "CWMainCollectionViewFlowLayout.h"

#define kShouldPlayDemoSound @"kShouldPlayDemoSound"
#define kEggShakerReuseIdentifier @"EggShaker"
#define kCurrentPageRestoreKey @"kCurrentPageRestoreKey"

#define iPad129Width 1366
#define iPad105Width 1112

@interface CWMainCollectionViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, strong) MotionTracker *motionTracker;
@property (nonatomic, strong) CWAudioHandler *audioHandler;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (weak, nonatomic) IBOutlet UILabel *shakeItLabel;
#if TARGET_OS_IOS
@property (weak, nonatomic) IBOutlet UISwitch *backgroundAudioSwitch;
#endif

@end

@implementation CWMainCollectionViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetCurrentPage) name:UIApplicationDidBecomeActiveNotification object:nil];
#if TARGET_OS_IOS
    self.backgroundAudioSwitch.on = [self.store boolForKey:kPlayAudioInBackgroundKey];
#endif
    self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.collectionView.allowsMultipleSelection = NO;

    self.audioHandler = [CWAudioHandler sharedHandler];
    self.motionTracker = [MotionTracker sharedTracker];

    if (!isPad) {

        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGFloat cellWidth = width - 110; //270;
        CGFloat right = (width - cellWidth)/2.;
        CGFloat left = right - ((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).sectionInset.left;
        self.collectionView.contentInset = UIEdgeInsetsMake(50, left, 50, right);

    } else {

        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        BOOL is129 = screenWidth == iPad129Width;
        BOOL is105 = screenWidth == iPad105Width;
        CGFloat leftInset = is129 ? 250 : is105 ? 125 : 80;
        CGFloat topInset = is129 ? 50 : 0;
        CGFloat bottomInset = is129 ? 100 : 0;
        self.collectionView.contentInset = UIEdgeInsetsMake(topInset, leftInset, bottomInset, 100);
    }
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    [self.motionTracker start];

    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session addObserver:self forKeyPath:@"outputVolume" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];

    [self changePage:0];
    [self changePage:1];
    [self changePage:0];
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    [[AVAudioSession sharedInstance] removeObserver:self forKeyPath:@"outputVolume"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {

    if ([keyPath isEqualToString:@"outputVolume"]) {
        CGFloat newValue = [change[NSKeyValueChangeNewKey] floatValue];
        [self volumeChanged:newValue];
    }
}

- (void)volumeChanged:(CGFloat)newValue {

    if (newValue < 0.01) {
        self.shakeItLabel.text = @"Volume is Turned Down";
    } else {
        self.shakeItLabel.text = @"Shake it!";
    }
}

- (CWInstrumentCollectionViewCell *)currentlySelectedCell {
    return (CWInstrumentCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentPage inSection:0]];
}

- (void)playSoundForCurrentPage {
    [self.audioHandler playExampleSoundForInstrument:[self currentlySelectedCell].instrument];
}

#pragma mark - Gesture recognizer

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
    NSUInteger newPage = ((int)targetContentOffset->x + self.cellWidth/2.) / self.cellWidth;
    [self changePage:newPage];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    
    NSUInteger newPage = ((int)scrollView.contentOffset.x + self.cellWidth/2.) / self.cellWidth;
    [self changePage:newPage];
}

#if TARGET_OS_TV
- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    [self changePage:indexPath.item];
}
#endif

- (CGFloat)cellWidth {
    
    if ([self.collectionViewLayout respondsToSelector:@selector(cellWidth)]) {
        return ((CWMainCollectionViewFlowLayout *)self.collectionViewLayout).cellWidth;
    }
    return MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)/2.;
}

- (void)changePage:(NSUInteger)newPage {

    [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:newPage inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    CWInstrumentCollectionViewCell *cell = [self currentlySelectedCell];
    [cell.scrollLockIndicatorLabel glowTwice];

    [self.motionTracker start];
    [self playDemoSoundForPage:newPage];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[self currentlySelectedCell] pulseBuyText];
    });
}

- (void)playDemoSoundForPage:(NSInteger)newPage {
    
    if (self.currentPage != newPage) {
        
        double delayInSeconds = 0.6;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
            [self playSoundForCurrentPage];
        });
        
        self.currentPage = newPage;
    }
}

#if TARGET_OS_IOS
- (IBAction)playInBackgroundSwitchChanged:(UISwitch *)sender {
    [self.store setBool:sender.on forKey:kPlayAudioInBackgroundKey];
}
#endif

#pragma mark - Collection view methods

- (CWInstrumentCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CWInstrumentCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kEggShakerReuseIdentifier forIndexPath:indexPath];
    
    [cell configureWithInstrument:[CWInstrumentFactory instrumentAtIndex:(Instrument)indexPath.item]];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CWInstrumentCollectionViewCell *cell = (CWInstrumentCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    BOOL selecting = !cell.isSelectedInstrument;
    cell.isSelectedInstrument = selecting;
    
    if (cell.isSelectedInstrument) {
        
        [self.audioHandler setActiveInstrument:cell.instrument];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [CWInstrumentFactory numberOfInstruments];
}

#pragma mark - Misc

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeInteger:self.currentPage forKey:kCurrentPageRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    self.currentPage = [coder decodeIntegerForKey:kCurrentPageRestoreKey];
}

- (void)resetCurrentPage {
    
    CWInstrumentCollectionViewCell *cell = [self currentlySelectedCell];
    [self.audioHandler setActiveInstrument:cell.instrument];
    
    [self changePage:self.currentPage];
}

#pragma mark - Properties

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (NSUserDefaults *)store {
    return [NSUserDefaults standardUserDefaults];
}

#if TARGET_OS_IOS
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
#endif

@end

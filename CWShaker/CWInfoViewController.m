//
//  CWInfoViewController.m
//  CWShaker
//
//  Created by C Williams on 06/11/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

#if TARGET_OS_IOS
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#endif

#import "CWInfoViewController.h"
#import "MotionTracker.h"

#define kAwesomeFontName @"FontAwesome"
#define kBuyItString @"Buy now:"
#define kiTunesAppURL @"https://itunes.apple.com/us/app/jingle/id737479996?ls=1&mt=8"
#define kCWTwitterScreenName @"buildsucceeded"
#define kOtherAppsByCWStoreURL @"itms-apps://itunes.apple.com/gb/artist/charlie-williams/id416450484"

#define kConnectionErrorString NSLocalizedString(@"(Error connecting to App Store)", nil)
#define kFollowOnTwitterAlertViewTag 1

@interface CWInfoViewController ()

@property (weak, nonatomic) IBOutlet UIButton *tweetMeButton;
@property (weak, nonatomic) IBOutlet UILabel *taglineLabel;

@end

@implementation CWInfoViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self addAttributesToStringsInNibs];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
#if TARGET_OS_IOS
    [self.motionTracker stop];
#endif
}

- (IBAction)tweetMeAction:(id)sender {
    
#if TARGET_OS_IOS
    SLComposeViewController *twitterVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    [twitterVC setInitialText:@"Happy jingling! @buildsucceeded https://itunes.apple.com/us/app/jingle+/id737479996?mt=8"];
    [self presentViewController:twitterVC animated:YES completion:nil];
#endif
}

- (IBAction)donePressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - stuff about me and twitter

- (void)addAttributesToStringsInNibs {
    
#if TARGET_OS_TV
    UIFont *awesomeFont = [UIFont fontWithName:kAwesomeFontName size:34];
#else
    UIFont *awesomeFont = [UIFont fontWithName:kAwesomeFontName size:14];
#endif
    
    NSString *socialString = self.tweetMeButton.titleLabel.text ?: @"an app by @buildsucceeded. Tweet me!";
    UIFont *socialFont = self.tweetMeButton.titleLabel.font ?: [UIFont systemFontOfSize:24];

    NSMutableAttributedString *tweetMeString = [[NSMutableAttributedString alloc] initWithString:socialString attributes:@{NSFontAttributeName:socialFont}];
    NSMutableAttributedString *twitterBird = [[NSMutableAttributedString alloc] initWithString:@" " attributes:@{NSFontAttributeName:awesomeFont}];
    
    [tweetMeString appendAttributedString:twitterBird];
    
    [self.tweetMeButton setAttributedTitle:tweetMeString forState:UIControlStateNormal];
    [self.tweetMeButton setTintColor:[UIColor whiteColor]];
    
    [self.taglineLabel setAttributedText:tweetMeString];
}

- (IBAction)viewOtherAppsAction:(id)sender {
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kOtherAppsByCWStoreURL]];
}

#pragma mark - Properties

- (MotionTracker *)motionTracker {
    return [MotionTracker sharedTracker];
}

@end

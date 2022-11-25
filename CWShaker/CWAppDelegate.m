//
//  CWAppDelegate.m
//  CWShaker
//
//  Created by C Williams on 02/11/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

#import "CWAppDelegate.h"
#import "CWAudioHandler.h"


@implementation CWAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [self.store registerDefaults:@{kPlayAudioInBackgroundKey:@YES}];

    [[CWAudioHandler sharedHandler] start];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    if (![self playAudioInBackground]) {
        [[CWAudioHandler sharedHandler] stop];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    if (![self playAudioInBackground]) {
        [[CWAudioHandler sharedHandler] start];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[CWAudioHandler sharedHandler] stop];
}

- (BOOL)playAudioInBackground {
    return [self.store boolForKey:kPlayAudioInBackgroundKey];
}

- (NSUserDefaults *)store {
    return [NSUserDefaults standardUserDefaults];
}

@end

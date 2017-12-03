//
//  CWTwitterRequestFollow.h
//

#if TARGET_OS_IOS
#import "CWTwitterRequest.h"

typedef void (^CWTwitterFollowCompletionBlock) (NSString *userId, NSString *screenName, BOOL success, NSError *error);

@interface CWTwitterRequestFollow : CWTwitterRequest

- (void)followUserWithScreenName:(NSString *)screenName completion:(CWTwitterFollowCompletionBlock)completion;

@end

#endif

//
//  CWTwitterAccount.h
//

#if TARGET_OS_IOS
#import <Social/Social.h>

#define kTwitterAccessKey @"twitterAccessKey"

#define kTwitterScreenNameKey @"screen_name"
#define kTwitterFollowingKey @"following"
#define kTwitterLookupConnectionsKey @"connections"
#define kTwitterUserIdStringKey @"id_str"

typedef void (^CWTwitterLookupCompletionBlock) (NSString *userId, NSString *screenName, BOOL isFollowing, NSError *error);

@interface CWTwitterRequest : NSObject <NSURLConnectionDataDelegate>

@property (nonatomic, strong) ACAccount *authorizedAccount;

- (id)initWithAccount:(ACAccount *)account;
- (SLRequest *)buildAuthorizedTwitterRequestWithURL:(NSString *)inURL requestMethod:(SLRequestMethod)method parameters:(NSDictionary *)params error:(NSError **)error;

@end

#endif

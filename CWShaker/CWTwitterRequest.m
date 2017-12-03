//
//  SHTwitterAccount.m
//

#if TARGET_OS_IOS
#import "CWTwitterRequest.h"
#import <Accounts/Accounts.h>

@implementation CWTwitterRequest

- (id)initWithAccount:(ACAccount *)account {
    
    if ((self = [super init])) {
        self.authorizedAccount = account;
    }
    
    return self;
    
}

- (SLRequest *)buildAuthorizedTwitterRequestWithURL:(NSString *)inURL requestMethod:(SLRequestMethod)method parameters:(NSDictionary *)params error:(NSError **)error {
    
    //Not sure why, but for some reason, the account type is sometimes missing, by re-setting it we stand a better chance of sucess
    if (self.authorizedAccount.accountType == nil) {
        
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *twitterAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        self.authorizedAccount.accountType = twitterAccountType;
        DLog(@"Setting missing account type: %@", self.authorizedAccount.accountType);
    }
    
    if (!self.authorizedAccount) {
        
        if (error) {
            DLog(@"Error with twitter request: %@", *error);
        }
        return nil;
    }
    
    NSURL *url = [NSURL URLWithString:inURL];
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:method URL:url parameters:params];
    [request setAccount:self.authorizedAccount];
    return request;
}

@end

#endif

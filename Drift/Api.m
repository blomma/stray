//
//  Poke.m
//  Drift
//
//  Created by Mikael Hultgren on 2013-02-26.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import "Api.h"

@implementation Api

- (id)init {
    self = [super init];
    if (self) {
    }

    return self;
}

#pragma mark -
#pragma mark Class methods

+ (Api *)instance {
    static Api *sharedApi = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedApi = [[self alloc] init];
    });

    return sharedApi;
}

#pragma mark -
#pragma mark Private methods

- (void)sendAuthenticatedJSONRequestToUrl:(NSURL *)url WithData:(NSData *)data {
    NSString *token = @"3e881af0833faa2be405e81063116836";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];

    [request setHTTPMethod:@"POST"];

    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    [request setHTTPBody: data];

    NSString *authHeader = [NSString stringWithFormat:@"Token token=%@", token];
    [request addValue:authHeader forHTTPHeaderField:@"Authorization"];

    id urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

#pragma mark -
#pragma mark Public methods

- (void)poke {
    NSString *iosVersion = [[UIDevice currentDevice] systemVersion];
    NSString *appBuild = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];

    NSDictionary *jsonDictionary = @{@"poke": @{
                                             @"ios_version":iosVersion,
                                             @"app_build":appBuild,
                                             @"app_version":appVersion,
                                             @"app_name":appName
                                             }};

    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];

    if (error) {
        return;
    }

    NSURL *url = [NSURL URLWithString:@"https://api.artsoftheinsane.com/pokes/"];

    [self sendAuthenticatedJSONRequestToUrl:url WithData:data];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {

    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    DLog(@"%@", error);
}

@end

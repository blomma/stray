//
//  Poke.h
//  Drift
//
//  Created by Mikael Hultgren on 2013-02-26.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Api : NSObject <NSURLConnectionDelegate>

+ (Api *)instance;
- (void)poke;

@end


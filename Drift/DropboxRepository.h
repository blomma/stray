//
//  DropboxRepository.h
//  Drift
//
//  Created by Mikael Hultgren on 2013-05-16.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Dropbox/Dropbox.h>

@interface DropboxRepository : NSObject

+ (DropboxRepository *)instance;

- (void)setup;
- (BOOL)handleOpenURL:(NSURL *)url;

@end

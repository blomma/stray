//
//  DropboxRepository.h
//  Drift
//
//  Created by Mikael Hultgren on 2013-05-16.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import <Dropbox/Dropbox.h>

@interface DropboxRepository : NSObject

@property (nonatomic, readonly) DBAccount *account;
@property (nonatomic, readonly) BOOL isSyncing;

+ (DropboxRepository *)instance;

- (void)setupWithAccount:(DBAccount *)account;
- (BOOL)handleOpenURL:(NSURL *)url;
- (void)sync;
- (void)link;
- (void)unLink;

@end
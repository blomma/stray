//
//  DataManager.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-29.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventGroups.h"
#import "Tags.h"
#import "State.h"

FOUNDATION_EXPORT NSString *const kDataManagerDidSaveNotification;

FOUNDATION_EXPORT NSString *const kTagChangesKey;
FOUNDATION_EXPORT NSString *const kEventChangesKey;
FOUNDATION_EXPORT NSString *const kEventGroupChangesKey;

@interface DataManager : NSObject

@property (nonatomic, readonly) EventGroups *eventGroups;
@property (nonatomic, readonly) NSArray *tags;
@property (nonatomic, readonly) State *state;

+ (DataManager *)instance;

- (Tag *)createTag;
- (void)deleteTag:(Tag *)tag;

@end

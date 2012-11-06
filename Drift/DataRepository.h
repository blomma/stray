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
#import "UIState.h"

FOUNDATION_EXPORT NSString *const kDataManagerObjectsDidChangeNotification;

@interface DataRepository : NSObject

@property (nonatomic, readonly) Tags *tags;
@property (nonatomic, readonly) UIState *state;
@property (nonatomic, readonly) NSArray *events;

+ (DataRepository *)instance;

- (Tag *)createTag;
- (void)deleteTag:(Tag *)tag;
- (void)deleteEvent:(Event *)event;

@end

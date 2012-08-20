//
//  EventGroupChange.h
//  Drift
//
//  Created by Mikael Hultgren on 8/13/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

FOUNDATION_EXPORT NSString *const EventGroupChangeInsert;
FOUNDATION_EXPORT NSString *const EventGroupChangeDelete;
FOUNDATION_EXPORT NSString *const EventGroupChangeUpdate;

@interface EventGroupChange : NSObject

@property (nonatomic) NSString *GUID;
@property (nonatomic) NSUInteger index;
@property (nonatomic) NSString *type;

@end

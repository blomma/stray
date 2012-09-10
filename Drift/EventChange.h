//
//  EventChange.h
//  Drift
//
//  Created by Mikael Hultgren on 9/8/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const EventChangeInsert;
FOUNDATION_EXPORT NSString *const EventChangeDelete;
FOUNDATION_EXPORT NSString *const EventChangeUpdate;

@interface EventChange : NSObject

@property (nonatomic) NSString *GUID;
@property (nonatomic) NSUInteger index;
@property (nonatomic) NSString *type;

@end

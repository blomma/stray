//
//  EventDataManager.h
//  Drift
//
//  Created by Mikael Hultgren on 7/25/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EventDataManager : NSObject

+ (id)sharedManager;

- (Event *)createEvent;
- (void)deleteEvent:(Event *)event;
- (Event *)latestEvent;
- (void)persistCurrentEvent;

@end

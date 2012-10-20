//
//  Global.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-17.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Global : NSObject

@property (nonatomic) NSCalendar *calendar;

+ (Global *)instance;

@end
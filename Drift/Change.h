//
//  Change.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-29.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const ChangeInsert;
FOUNDATION_EXPORT NSString *const ChangeDelete;
FOUNDATION_EXPORT NSString *const ChangeUpdate;

@interface Change : NSObject

@property (nonatomic) NSUInteger index;
@property (nonatomic) NSString *type;
@property (nonatomic) id object;
@property (nonatomic) id parentObject;

@end

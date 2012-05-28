//
//  Event.h
//  Drift
//
//  Created by Mikael Hultgren on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Event : NSManagedObject

@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *stopDate;
@property (nonatomic) NSString *tag;

@end

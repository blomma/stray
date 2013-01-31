//
//  DataManager.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-29.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "DataRepository.h"

NSString *const kDataManagerObjectsDidChangeNotification = @"kDataManagerObjectsDidChangeNotification";

@interface DataRepository ()

@property (nonatomic) State *state;

@end

@implementation DataRepository

-(int)getRandomNumber:(int)from to:(int)to {
    return (int)(from + (int)arc4random() % (to - from + 1));
}

- (void)populateRandomData {
    NSMutableArray *tags = [NSMutableArray array];

    Tag *tag = [Tag MR_createEntity];
    tag.name = @"Work";
    [tags addObject:tag];

    tag      = [Tag MR_createEntity];
    tag.name = @"Fun";
    [tags addObject:tag];

    tag      = [Tag MR_createEntity];
    tag.name = @"Reading";
    [tags addObject:tag];

    tag      = [Tag MR_createEntity];
    tag.name = @"Lunch";
    [tags addObject:tag];

    NSDate *nowDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    for (int i = 0; i < 365; i++) {
        NSTimeInterval interval = 60 * 60 * 24 * i;

        Event *event = [Event MR_createEntity];
        event.startDate = nowDate;
        nowDate         = [NSDate dateWithTimeIntervalSinceReferenceDate:interval];
        event.stopDate  = nowDate;
        event.inTag     = [tags objectAtIndex:[self getRandomNumber:0 to:3]];
    }
}

- (id)init {
    self = [super init];
    if (self) {

        self.state = [[State alloc] init];

        //[self populateRandomData];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(objectsDidChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:[NSManagedObjectContext MR_defaultContext]];
    }

    return self;
}

#pragma mark -
#pragma mark Public properties

- (NSArray *)tags {
    return [Tag MR_findAll];
}

- (NSArray *)events {
    return [Event MR_findAll];
}

#pragma mark -
#pragma mark Class methods

+ (DataRepository *)instance {
    static DataRepository *sharedDataManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
            sharedDataManager = [[self alloc] init];
        });

    return sharedDataManager;
}

#pragma mark -
#pragma mark Private methods

- (void)objectsDidChange:(NSNotification *)note {
    [[NSNotificationCenter defaultCenter] postNotificationName:kDataManagerObjectsDidChangeNotification
                                                        object:self
                                                      userInfo:[note userInfo]];
}

@end

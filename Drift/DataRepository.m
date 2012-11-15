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

@property (nonatomic) UIState *state;
@property (nonatomic) Tags *tags;

@end

@implementation DataRepository

//-(int)getRandomNumber:(int)from to:(int)to {
//    return (int)from + arc4random() % (to-from+1);
//}

- (id)init {
    self = [super init];
    if (self) {

        self.state = [UIState MR_findFirstByAttribute:@"name" withValue:@"default"];

        if (!self.state) {
            self.state      = [UIState MR_createEntity];
            self.state.name = @"default";
        }


//        NSMutableArray *tags = [NSMutableArray array];
//
//        Tag *tag = [self createTag];
//        tag.name = @"Work";
//        [tags addObject:tag];
//
//        tag = [self createTag];
//        tag.name = @"Fun";
//        [tags addObject:tag];
//
//        tag = [self createTag];
//        tag.name = @"Reading";
//        [tags addObject:tag];
//
//        tag = [self createTag];
//        tag.name = @"Lunch";
//        [tags addObject:tag];
//
//        NSDate *nowDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
//        for (int i = 0; i < 1000; i++) {
//            NSTimeInterval interval = 60 * [self getRandomNumber:60 to:300];
//
//            Event *event = [self createEvent];
//            event.startDate = nowDate;
//            nowDate = [nowDate dateByAddingTimeInterval:interval];
//            event.stopDate = nowDate;
//            event.inTag = [tags objectAtIndex:[self getRandomNumber:0 to:2]];
//        }

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(objectsDidChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:[NSManagedObjectContext MR_defaultContext]];
    }

    return self;
}

#pragma mark -
#pragma mark Public properties

- (Tags *)tags {
    if (!_tags) {
        _tags = [[Tags alloc] initWithTags:[Tag MR_findAll]];
    }

    return _tags;
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
#pragma mark Public methods

- (Tag *)createTag {
    return [Tag MR_createEntity];
}

- (void)deleteTag:(Tag *)tag {
    [tag MR_deleteEntity];
}

- (Event *)createEvent {
    return [Event MR_createEntity];
}

- (void)deleteEvent:(Event *)event {
    [event MR_deleteEntity];
}

#pragma mark -
#pragma mark Private methods

- (void)objectsDidChange:(NSNotification *)note {
    [[NSNotificationCenter defaultCenter] postNotificationName:kDataManagerObjectsDidChangeNotification
                                                        object:self
                                                      userInfo:[note userInfo]];
}

@end
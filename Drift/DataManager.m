//
//  DataManager.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-29.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "DataManager.h"
#import "NSManagedObject+ActiveRecord.h"
#import "Event.h"
#import "Tag.h"

NSString *const kDataManagerObjectsDidChangeNotification = @"kDataManagerObjectsDidChangeNotification";

@interface DataManager ()

@property (nonatomic) UIState *state;

@end

@implementation DataManager

#pragma mark -
#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (self) {

        self.state = [UIState where:@{ @"name" : @"default" }].first;

        if (!self.state) {
            self.state = [UIState create];
            self.state.name = @"default";
        }

//        if ([Event all].count == 0) {
//            NSDate *nowDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
//            NSTimeInterval interval = 60 * 60 * 5;
//
//            Tag *tag = [Tag create];
//            tag.name = @"Test1";
//            
//            for (int i = 0; i < 1000; i++) {
//                Event *event = [Event create];
//                event.startDate = nowDate;
//                nowDate = [nowDate dateByAddingTimeInterval:interval];
//                event.stopDate = nowDate;
//                event.inTag = tag;
//            }
//
//            Tag *tag2 = [Tag create];
//            tag2.name = @"Test2";
//
//            for (int i = 0; i < 1000; i++) {
//                Event *event = [Event create];
//                event.startDate = nowDate;
//                nowDate = [nowDate dateByAddingTimeInterval:interval];
//                event.stopDate = nowDate;
//                event.inTag = tag2;
//            }
//        }
//#ifdef ADHOC
//#endif

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(objectsDidChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:[[CoreDataManager instance] managedObjectContext]];
    }

    return self;
}

#pragma mark -
#pragma mark Public properties

- (NSArray *)tags {
    return [Tag all];
}

- (NSArray *)events {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"startDate" ascending:YES];
    return [Event where:nil
              inContext:[NSManagedObjectContext defaultContext]
    withSortDescriptors:@[sortDescriptor]];
}

#pragma mark -
#pragma mark Class methods

+ (DataManager *)instance {
	static DataManager *sharedDataManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedDataManager = [[self alloc] init];
	});

	return sharedDataManager;
}

#pragma mark -
#pragma mark Public methods

- (Tag *)createTag {
    return [Tag create];
}

- (void)deleteTag:(Tag *)tag {
    [tag delete];
}

#pragma mark -
#pragma mark Private methods

- (void)objectsDidChange:(NSNotification *)note {
    [[NSNotificationCenter defaultCenter] postNotificationName:kDataManagerObjectsDidChangeNotification
                                                        object:self
                                                      userInfo:[note userInfo]];
}

@end

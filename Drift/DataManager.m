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
    return [Event all];
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

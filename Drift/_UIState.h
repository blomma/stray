// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to UIState.h instead.

#import <CoreData/CoreData.h>


extern const struct UIStateAttributes {
	__unsafe_unretained NSString *name;
} UIStateAttributes;

extern const struct UIStateRelationships {
	__unsafe_unretained NSString *activeEvent;
	__unsafe_unretained NSString *eventGroupsFilter;
} UIStateRelationships;

extern const struct UIStateFetchedProperties {
} UIStateFetchedProperties;

@class Event;
@class Tag;



@interface UIStateID : NSManagedObjectID {}
@end

@interface _UIState : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (UIStateID*)objectID;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) Event *activeEvent;

//- (BOOL)validateActiveEvent:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSSet *eventGroupsFilter;

- (NSMutableSet*)eventGroupsFilterSet;





@end

@interface _UIState (CoreDataGeneratedAccessors)

- (void)addEventGroupsFilter:(NSSet*)value_;
- (void)removeEventGroupsFilter:(NSSet*)value_;
- (void)addEventGroupsFilterObject:(Tag*)value_;
- (void)removeEventGroupsFilterObject:(Tag*)value_;

@end

@interface _UIState (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;





- (Event*)primitiveActiveEvent;
- (void)setPrimitiveActiveEvent:(Event*)value;



- (NSMutableSet*)primitiveEventGroupsFilter;
- (void)setPrimitiveEventGroupsFilter:(NSMutableSet*)value;


@end

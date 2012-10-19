// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Tag.h instead.

#import <CoreData/CoreData.h>


extern const struct TagAttributes {
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *sortIndex;
} TagAttributes;

extern const struct TagRelationships {
	__unsafe_unretained NSString *heldByEvents;
	__unsafe_unretained NSString *heldByEventsGroupFilter;
} TagRelationships;

extern const struct TagFetchedProperties {
} TagFetchedProperties;

@class Event;
@class UIState;




@interface TagID : NSManagedObjectID {}
@end

@interface _Tag : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (TagID*)objectID;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* sortIndex;



@property int64_t sortIndexValue;
- (int64_t)sortIndexValue;
- (void)setSortIndexValue:(int64_t)value_;

//- (BOOL)validateSortIndex:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *heldByEvents;

- (NSMutableSet*)heldByEventsSet;




@property (nonatomic, strong) UIState *heldByEventsGroupFilter;

//- (BOOL)validateHeldByEventsGroupFilter:(id*)value_ error:(NSError**)error_;





@end

@interface _Tag (CoreDataGeneratedAccessors)

- (void)addHeldByEvents:(NSSet*)value_;
- (void)removeHeldByEvents:(NSSet*)value_;
- (void)addHeldByEventsObject:(Event*)value_;
- (void)removeHeldByEventsObject:(Event*)value_;

@end

@interface _Tag (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSNumber*)primitiveSortIndex;
- (void)setPrimitiveSortIndex:(NSNumber*)value;

- (int64_t)primitiveSortIndexValue;
- (void)setPrimitiveSortIndexValue:(int64_t)value_;





- (NSMutableSet*)primitiveHeldByEvents;
- (void)setPrimitiveHeldByEvents:(NSMutableSet*)value;



- (UIState*)primitiveHeldByEventsGroupFilter;
- (void)setPrimitiveHeldByEventsGroupFilter:(UIState*)value;


@end

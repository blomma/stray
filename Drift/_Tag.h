// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Tag.h instead.

@import CoreData;

extern const struct TagAttributes {
	__unsafe_unretained NSString *guid;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *sortIndex;
} TagAttributes;

extern const struct TagRelationships {
	__unsafe_unretained NSString *heldByEvents;
} TagRelationships;

@class Event;

@interface TagID : NSManagedObjectID {}
@end

@interface _Tag : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) TagID* objectID;

@property (nonatomic, strong) NSString* guid;

//- (BOOL)validateGuid:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* name;

//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* sortIndex;

@property (atomic) int64_t sortIndexValue;
- (int64_t)sortIndexValue;
- (void)setSortIndexValue:(int64_t)value_;

//- (BOOL)validateSortIndex:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *heldByEvents;

- (NSMutableSet*)heldByEventsSet;

@end

@interface _Tag (HeldByEventsCoreDataGeneratedAccessors)
- (void)addHeldByEvents:(NSSet*)value_;
- (void)removeHeldByEvents:(NSSet*)value_;
- (void)addHeldByEventsObject:(Event*)value_;
- (void)removeHeldByEventsObject:(Event*)value_;

@end

@interface _Tag (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveGuid;
- (void)setPrimitiveGuid:(NSString*)value;

- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;

- (NSNumber*)primitiveSortIndex;
- (void)setPrimitiveSortIndex:(NSNumber*)value;

- (int64_t)primitiveSortIndexValue;
- (void)setPrimitiveSortIndexValue:(int64_t)value_;

- (NSMutableSet*)primitiveHeldByEvents;
- (void)setPrimitiveHeldByEvents:(NSMutableSet*)value;

@end

// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Tag.h instead.

#import <CoreData/CoreData.h>


extern const struct TagAttributes {
	__unsafe_unretained NSString *name;
} TagAttributes;

extern const struct TagRelationships {
	__unsafe_unretained NSString *heldByEvents;
} TagRelationships;

extern const struct TagFetchedProperties {
} TagFetchedProperties;

@class Event;



@interface TagID : NSManagedObjectID {}
@end

@interface _Tag : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (TagID*)objectID;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *heldByEvents;

- (NSMutableSet*)heldByEventsSet;





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





- (NSMutableSet*)primitiveHeldByEvents;
- (void)setPrimitiveHeldByEvents:(NSMutableSet*)value;


@end

// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Tag.h instead.

#import <CoreData/CoreData.h>


extern const struct TagAttributes {
	__unsafe_unretained NSString *name;
} TagAttributes;

extern const struct TagRelationships {
	__unsafe_unretained NSString *heldBy;
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





@property (nonatomic, strong) NSSet *heldBy;

- (NSMutableSet*)heldBySet;





@end

@interface _Tag (CoreDataGeneratedAccessors)

- (void)addHeldBy:(NSSet*)value_;
- (void)removeHeldBy:(NSSet*)value_;
- (void)addHeldByObject:(Event*)value_;
- (void)removeHeldByObject:(Event*)value_;

@end

@interface _Tag (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;





- (NSMutableSet*)primitiveHeldBy;
- (void)setPrimitiveHeldBy:(NSMutableSet*)value;


@end

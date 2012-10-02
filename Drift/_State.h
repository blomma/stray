// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to State.h instead.

#import <CoreData/CoreData.h>


extern const struct StateAttributes {
	__unsafe_unretained NSString *name;
} StateAttributes;

extern const struct StateRelationships {
	__unsafe_unretained NSString *inEvent;
} StateRelationships;

extern const struct StateFetchedProperties {
} StateFetchedProperties;

@class Event;



@interface StateID : NSManagedObjectID {}
@end

@interface _State : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (StateID*)objectID;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) Event *inEvent;

//- (BOOL)validateInEvent:(id*)value_ error:(NSError**)error_;





@end

@interface _State (CoreDataGeneratedAccessors)

@end

@interface _State (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;





- (Event*)primitiveInEvent;
- (void)setPrimitiveInEvent:(Event*)value;


@end

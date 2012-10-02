// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Event.h instead.

#import <CoreData/CoreData.h>


extern const struct EventAttributes {
	__unsafe_unretained NSString *startDate;
	__unsafe_unretained NSString *stopDate;
} EventAttributes;

extern const struct EventRelationships {
	__unsafe_unretained NSString *heldByState;
	__unsafe_unretained NSString *inTag;
} EventRelationships;

extern const struct EventFetchedProperties {
} EventFetchedProperties;

@class State;
@class Tag;




@interface EventID : NSManagedObjectID {}
@end

@interface _Event : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EventID*)objectID;





@property (nonatomic, strong) NSDate* startDate;



//- (BOOL)validateStartDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* stopDate;



//- (BOOL)validateStopDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) State *heldByState;

//- (BOOL)validateHeldByState:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) Tag *inTag;

//- (BOOL)validateInTag:(id*)value_ error:(NSError**)error_;





@end

@interface _Event (CoreDataGeneratedAccessors)

@end

@interface _Event (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveStartDate;
- (void)setPrimitiveStartDate:(NSDate*)value;




- (NSDate*)primitiveStopDate;
- (void)setPrimitiveStopDate:(NSDate*)value;





- (State*)primitiveHeldByState;
- (void)setPrimitiveHeldByState:(State*)value;



- (Tag*)primitiveInTag;
- (void)setPrimitiveInTag:(Tag*)value;


@end

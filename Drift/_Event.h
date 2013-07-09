// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Event.h instead.

#import <CoreData/CoreData.h>


extern const struct EventAttributes {
	__unsafe_unretained NSString *guid;
	__unsafe_unretained NSString *startDate;
	__unsafe_unretained NSString *stopDate;
} EventAttributes;

extern const struct EventRelationships {
	__unsafe_unretained NSString *inRepositories;
	__unsafe_unretained NSString *inTag;
} EventRelationships;

extern const struct EventFetchedProperties {
} EventFetchedProperties;

@class Repository;
@class Tag;





@interface EventID : NSManagedObjectID {}
@end

@interface _Event : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EventID*)objectID;





@property (nonatomic, strong) NSString* guid;



//- (BOOL)validateGuid:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* startDate;



//- (BOOL)validateStartDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* stopDate;



//- (BOOL)validateStopDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *inRepositories;

- (NSMutableSet*)inRepositoriesSet;




@property (nonatomic, strong) Tag *inTag;

//- (BOOL)validateInTag:(id*)value_ error:(NSError**)error_;





@end

@interface _Event (CoreDataGeneratedAccessors)

- (void)addInRepositories:(NSSet*)value_;
- (void)removeInRepositories:(NSSet*)value_;
- (void)addInRepositoriesObject:(Repository*)value_;
- (void)removeInRepositoriesObject:(Repository*)value_;

@end

@interface _Event (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveGuid;
- (void)setPrimitiveGuid:(NSString*)value;




- (NSDate*)primitiveStartDate;
- (void)setPrimitiveStartDate:(NSDate*)value;




- (NSDate*)primitiveStopDate;
- (void)setPrimitiveStopDate:(NSDate*)value;





- (NSMutableSet*)primitiveInRepositories;
- (void)setPrimitiveInRepositories:(NSMutableSet*)value;



- (Tag*)primitiveInTag;
- (void)setPrimitiveInTag:(Tag*)value;


@end

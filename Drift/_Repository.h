// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Repository.h instead.

#import <CoreData/CoreData.h>


extern const struct RepositoryAttributes {
	__unsafe_unretained NSString *lastSynced;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *path;
} RepositoryAttributes;

extern const struct RepositoryRelationships {
	__unsafe_unretained NSString *heldByEvent;
} RepositoryRelationships;

extern const struct RepositoryFetchedProperties {
} RepositoryFetchedProperties;

@class Event;





@interface RepositoryID : NSManagedObjectID {}
@end

@interface _Repository : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (RepositoryID*)objectID;





@property (nonatomic, strong) NSDate* lastSynced;



//- (BOOL)validateLastSynced:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* path;



//- (BOOL)validatePath:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) Event *heldByEvent;

//- (BOOL)validateHeldByEvent:(id*)value_ error:(NSError**)error_;





@end

@interface _Repository (CoreDataGeneratedAccessors)

@end

@interface _Repository (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveLastSynced;
- (void)setPrimitiveLastSynced:(NSDate*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSString*)primitivePath;
- (void)setPrimitivePath:(NSString*)value;





- (Event*)primitiveHeldByEvent;
- (void)setPrimitiveHeldByEvent:(Event*)value;


@end

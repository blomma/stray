// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Event.h instead.

@import CoreData;

extern const struct EventAttributes {
	__unsafe_unretained NSString *exported;
	__unsafe_unretained NSString *guid;
	__unsafe_unretained NSString *startDate;
	__unsafe_unretained NSString *stopDate;
} EventAttributes;

extern const struct EventRelationships {
	__unsafe_unretained NSString *inTag;
} EventRelationships;

@class Tag;

@interface EventID : NSManagedObjectID {}
@end

@interface _Event : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EventID* objectID;

@property (nonatomic, strong) NSNumber* exported;

@property (atomic) BOOL exportedValue;
- (BOOL)exportedValue;
- (void)setExportedValue:(BOOL)value_;

//- (BOOL)validateExported:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* guid;

//- (BOOL)validateGuid:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* startDate;

//- (BOOL)validateStartDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* stopDate;

//- (BOOL)validateStopDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) Tag *inTag;

//- (BOOL)validateInTag:(id*)value_ error:(NSError**)error_;

@end

@interface _Event (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveExported;
- (void)setPrimitiveExported:(NSNumber*)value;

- (BOOL)primitiveExportedValue;
- (void)setPrimitiveExportedValue:(BOOL)value_;

- (NSString*)primitiveGuid;
- (void)setPrimitiveGuid:(NSString*)value;

- (NSDate*)primitiveStartDate;
- (void)setPrimitiveStartDate:(NSDate*)value;

- (NSDate*)primitiveStopDate;
- (void)setPrimitiveStopDate:(NSDate*)value;

- (Tag*)primitiveInTag;
- (void)setPrimitiveInTag:(Tag*)value;

@end

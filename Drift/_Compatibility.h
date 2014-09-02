// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Compatibility.h instead.

@import CoreData;

extern const struct CompatibilityAttributes {
	__unsafe_unretained NSString *level;
} CompatibilityAttributes;

@interface CompatibilityID : NSManagedObjectID {}
@end

@interface _Compatibility : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) CompatibilityID* objectID;

@property (nonatomic, strong) NSNumber* level;

@property (atomic) int64_t levelValue;
- (int64_t)levelValue;
- (void)setLevelValue:(int64_t)value_;

//- (BOOL)validateLevel:(id*)value_ error:(NSError**)error_;

@end

@interface _Compatibility (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveLevel;
- (void)setPrimitiveLevel:(NSNumber*)value;

- (int64_t)primitiveLevelValue;
- (void)setPrimitiveLevelValue:(int64_t)value_;

@end

// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Event.h instead.

#import <CoreData/CoreData.h>


extern const struct EventAttributes {
	__unsafe_unretained NSString *running;
	__unsafe_unretained NSString *runningTimeHours;
	__unsafe_unretained NSString *runningTimeMilliseconds;
	__unsafe_unretained NSString *runningTimeMinutes;
	__unsafe_unretained NSString *runningTimeSeconds;
	__unsafe_unretained NSString *startDate;
	__unsafe_unretained NSString *stopDate;
	__unsafe_unretained NSString *tag;
} EventAttributes;

extern const struct EventRelationships {
} EventRelationships;

extern const struct EventFetchedProperties {
} EventFetchedProperties;











@interface EventID : NSManagedObjectID {}
@end

@interface _Event : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EventID*)objectID;




@property (nonatomic, strong) NSNumber* running;


@property BOOL runningValue;
- (BOOL)runningValue;
- (void)setRunningValue:(BOOL)value_;

//- (BOOL)validateRunning:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* runningTimeHours;


@property int64_t runningTimeHoursValue;
- (int64_t)runningTimeHoursValue;
- (void)setRunningTimeHoursValue:(int64_t)value_;

//- (BOOL)validateRunningTimeHours:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* runningTimeMilliseconds;


@property int16_t runningTimeMillisecondsValue;
- (int16_t)runningTimeMillisecondsValue;
- (void)setRunningTimeMillisecondsValue:(int16_t)value_;

//- (BOOL)validateRunningTimeMilliseconds:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* runningTimeMinutes;


@property int16_t runningTimeMinutesValue;
- (int16_t)runningTimeMinutesValue;
- (void)setRunningTimeMinutesValue:(int16_t)value_;

//- (BOOL)validateRunningTimeMinutes:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* runningTimeSeconds;


@property int16_t runningTimeSecondsValue;
- (int16_t)runningTimeSecondsValue;
- (void)setRunningTimeSecondsValue:(int16_t)value_;

//- (BOOL)validateRunningTimeSeconds:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate* startDate;


//- (BOOL)validateStartDate:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate* stopDate;


//- (BOOL)validateStopDate:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* tag;


//- (BOOL)validateTag:(id*)value_ error:(NSError**)error_;






@end

@interface _Event (CoreDataGeneratedAccessors)

@end

@interface _Event (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveRunning;
- (void)setPrimitiveRunning:(NSNumber*)value;

- (BOOL)primitiveRunningValue;
- (void)setPrimitiveRunningValue:(BOOL)value_;




- (NSNumber*)primitiveRunningTimeHours;
- (void)setPrimitiveRunningTimeHours:(NSNumber*)value;

- (int64_t)primitiveRunningTimeHoursValue;
- (void)setPrimitiveRunningTimeHoursValue:(int64_t)value_;




- (NSNumber*)primitiveRunningTimeMilliseconds;
- (void)setPrimitiveRunningTimeMilliseconds:(NSNumber*)value;

- (int16_t)primitiveRunningTimeMillisecondsValue;
- (void)setPrimitiveRunningTimeMillisecondsValue:(int16_t)value_;




- (NSNumber*)primitiveRunningTimeMinutes;
- (void)setPrimitiveRunningTimeMinutes:(NSNumber*)value;

- (int16_t)primitiveRunningTimeMinutesValue;
- (void)setPrimitiveRunningTimeMinutesValue:(int16_t)value_;




- (NSNumber*)primitiveRunningTimeSeconds;
- (void)setPrimitiveRunningTimeSeconds:(NSNumber*)value;

- (int16_t)primitiveRunningTimeSecondsValue;
- (void)setPrimitiveRunningTimeSecondsValue:(int16_t)value_;




- (NSDate*)primitiveStartDate;
- (void)setPrimitiveStartDate:(NSDate*)value;




- (NSDate*)primitiveStopDate;
- (void)setPrimitiveStopDate:(NSDate*)value;




- (NSString*)primitiveTag;
- (void)setPrimitiveTag:(NSString*)value;




@end

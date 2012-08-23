//
//  EventGroupTableViewCell.m
//  Drift
//
//  Created by Mikael Hultgren on 7/28/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroupTableViewCell.h"

@interface EventGroupTableViewCell ()

@property (nonatomic, readwrite) EventGroup *eventGroup;

@end

@implementation EventGroupTableViewCell

#pragma mark -
#pragma mark Application lifecycle

- (void)awakeFromNib {
    self.weekDay.transform = CGAffineTransformMakeRotation (-3.14/2);
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
	}

	return self;
}

//- (void)drawRect:(CGRect)rect {
//    if (self.position == EventGroupTableViewCellPositionTop
//        || self.position == EventGroupTableViewCellPositionMiddle) {
//        [self drawLineSeparator:CGRectMake(rect.origin.x, rect.origin.y,
//                                           rect.size.width, rect.size.height)];
//    }
//}

#pragma mark -
#pragma mark Public instance methods

+ (NSArray *)monthNames {
    static NSArray *names = nil;
    if (names == nil) {
        names = [[NSDateFormatter new] shortStandaloneMonthSymbols];
    }

    return names;
}

+ (NSArray *)weekNames {
    static NSArray *names = nil;
    if (names == nil) {
        names = [[NSDateFormatter new] shortStandaloneWeekdaySymbols];
    }

    return names;
}

- (void)addEventGroup:(EventGroup *)eventGroup {
	self.eventGroup = eventGroup;

	[self updateTime];
}

#pragma mark -
#pragma mark Private instance methods

- (void) drawLineSeparator:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);

    CGContextMoveToPoint(ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect));

    CGFloat dashes[] = { 3, 20 };
    CGContextSetLineDash(ctx, 0, dashes, 2);
    CGColorRef color = [[UIColor colorWithRed:1.000 green:0.600 blue:0.008 alpha:1.000] CGColor];
    CGContextSetStrokeColorWithColor(ctx, color);
    CGContextSetLineWidth(ctx, 1);
    CGContextStrokePath(ctx);

    CGContextRestoreGState(ctx);
}

- (void)updateTime {
	NSDateComponents *components = self.eventGroup.timeActiveComponents;

	// And finally update the running timer
	self.hours.text   = [NSString stringWithFormat:@"%02d", components.hour];
	self.minutes.text = [NSString stringWithFormat:@"%02d", components.minute];

	unsigned int unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit;
	components = [[NSCalendar currentCalendar] components:unitFlags fromDate:self.eventGroup.groupDate];

	self.day.text   = [NSString stringWithFormat:@"%02d", components.day];
	self.year.text  = [NSString stringWithFormat:@"%04d", components.year];
	self.month.text = [[EventGroupTableViewCell monthNames] objectAtIndex:components.month - 1];
    self.weekDay.text  = [[[EventGroupTableViewCell weekNames] objectAtIndex:components.weekday - 1] uppercaseString];
}

@end

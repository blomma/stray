//
//  ClockView.m
//  Drift
//
//  Created by Mikael Hultgren on 6/16/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "ClockView.h"

@interface ClockView ()

@property(nonatomic) NSTimer *updateTimer;

@property(nonatomic) CAShapeLayer *hourHand;
@property(nonatomic) CAShapeLayer *minuteHand;
@property(nonatomic) CAShapeLayer *secondHand;

@end

@implementation ClockView

#pragma mark -
#pragma mark private properties

@synthesize updateTimer = updateTimer_;
@synthesize hourHand = hourHand_;
@synthesize minuteHand = minuteHand_;
@synthesize secondHand = secondHand_;

#pragma mark -
#pragma mark public properties

@synthesize startDate = startDate_;

- (id)initWithCoder:(NSCoder *)aDecoder 
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self setUpClock];
    }
	
    return self;
}

- (void)setUpClock 
{
    CAShapeLayer *face = [CAShapeLayer layer];
    
    // face
    face.bounds = self.bounds;
    face.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    face.fillColor = [[UIColor grayColor] CGColor];
    face.strokeColor = [[UIColor blackColor] CGColor];
    face.lineWidth = 4.0;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddEllipseInRect(path, nil, self.bounds);
    face.path = path;
    
    [self.layer addSublayer:face];
    
    // numbers
    for (NSInteger i=1; i <= 12; ++i) 
	{
        CATextLayer *number = [CATextLayer layer];
        number.string = [NSString stringWithFormat:@"%i", i];
        number.alignmentMode = @"center";
        number.fontSize = 18.0;
        number.foregroundColor = [[UIColor blackColor] CGColor];
        number.bounds = CGRectMake(0.0, 0.0, 25.0, self.bounds.size.height / 2.0 - 10.0);
        number.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        number.anchorPoint = CGPointMake(0.5, 1.0);
        number.transform = CATransform3DMakeRotation((M_PI * 2) / 12.0 * i, 0, 0, 1);
        
        [self.layer addSublayer:number];
    }    
    
    // ticks
    for (NSInteger i=1; i <= 60; ++i) 
	{
        CAShapeLayer *tick = [CAShapeLayer layer];
        
        path = CGPathCreateMutable();
        CGPathAddEllipseInRect(path, nil, CGRectMake(0.0, 0.0, 1.0, 5.0));
        
        tick.strokeColor = [[UIColor blackColor] CGColor];
        tick.bounds = CGRectMake(0.0, 0.0, 1.0, self.bounds.size.height / 2.0);
        tick.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        tick.anchorPoint = CGPointMake(0.5, 1.0);
        tick.transform = CATransform3DMakeRotation((M_PI * 2) / 60.0 * i, 0, 0, 1);
        tick.path = path;
        
        [self.layer addSublayer:tick];
    }    
    
    // second hand
    self.secondHand = [CAShapeLayer layer];
    
    path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, 1.0, 0.0);
    CGPathAddLineToPoint(path, nil, 1.0, self.bounds.size.height / 2.0 + 8.0);
    
    self.secondHand.bounds = CGRectMake(0.0, 0.0, 3.0, self.bounds.size.height / 2.0 + 8.0);
    self.secondHand.anchorPoint = CGPointMake(0.5, 0.8);
    self.secondHand.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.secondHand.lineWidth = 3.0;
    self.secondHand.strokeColor = [[UIColor redColor] CGColor];
    self.secondHand.path = path;
    self.secondHand.shadowOffset = CGSizeMake(0.0, 3.0);
    self.secondHand.shadowOpacity = 0.6;
    self.secondHand.lineCap = kCALineCapRound;
    
    [self.layer addSublayer:self.secondHand];
    
    // minute hand
    self.minuteHand = [CAShapeLayer layer];
    
    path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, 2.0, 0.0);
    CGPathAddLineToPoint(path, nil, 2.0, self.bounds.size.height / 2.0);
    
    self.minuteHand.bounds = CGRectMake(0.0, 0.0, 5.0, self.bounds.size.height / 2.0);
    self.minuteHand.anchorPoint = CGPointMake(0.5, 0.8);
    self.minuteHand.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.minuteHand.lineWidth = 5.0;
    self.minuteHand.strokeColor = [[UIColor blackColor] CGColor];
    self.minuteHand.path = path;
    self.minuteHand.shadowOffset = CGSizeMake(0.0, 3.0);
    self.minuteHand.shadowOpacity = 0.3;
    self.minuteHand.lineCap = kCALineCapRound;
    
    [self.layer addSublayer:self.minuteHand];
    
    // hour hand
    self.hourHand = [CAShapeLayer layer];
    
    path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, 3, 0);
    CGPathAddLineToPoint(path, nil, 3.0, self.bounds.size.height / 3.0);
    
    self.hourHand.bounds = CGRectMake(0.0, 0.0, 7.0, self.bounds.size.height / 3.0);
    self.hourHand.anchorPoint = CGPointMake(0.5, 0.8);
    self.hourHand.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.hourHand.lineWidth = 7.0;
    self.hourHand.strokeColor = [[UIColor blackColor] CGColor];
    self.hourHand.path = path;
    self.hourHand.shadowOffset = CGSizeMake(0.0, 3.0);
    self.hourHand.shadowOpacity = 0.3;
    self.hourHand.lineCap = kCALineCapRound;
    
    [self.layer addSublayer:self.hourHand];
    
    // midpoint
    CAShapeLayer *circle = [CAShapeLayer layer];
    
    path = CGPathCreateMutable();
    CGPathAddEllipseInRect(path, nil, CGRectMake(0.0, 0.0, 11.0, 11.0));
    
    circle.fillColor = [[UIColor yellowColor] CGColor];
    circle.bounds = CGRectMake(0.0, 0.0, 11.0, 11.0);
    circle.path = path;
    circle.shadowOpacity = 0.3;
    circle.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    circle.shadowOffset = CGSizeMake(0.0, 5.0);
    
    [self.layer addSublayer:circle];
    
    [self updateHands];
}

#pragma mark -

- (void)startUpdates 
{
	[self updateHands];
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 
														target:self 
													  selector:@selector(updateHands) 
													  userInfo:nil 
													   repeats:YES];
}

- (void)stopUpdates 
{
    [self.updateTimer invalidate];
    self.updateTimer = nil;
}

- (void)updateHands 
{
    NSDate *now = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [cal components:NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:now];
    
    NSInteger minutesIntoDay = [comps hour] * 60 + [comps minute];
    float percentageMinutesIntoDay = minutesIntoDay / (12.0 * 60.0);
    float percentageMinutesIntoHour = (float)[comps minute] / 60.0;
    float percentageSecondsIntoMinute = (float)[comps second] / 60.0;
    
    self.secondHand.transform = CATransform3DMakeRotation((M_PI * 2) * percentageSecondsIntoMinute, 0, 0, 1);
    self.minuteHand.transform = CATransform3DMakeRotation((M_PI * 2) * percentageMinutesIntoHour, 0, 0, 1);
    self.hourHand.transform = CATransform3DMakeRotation((M_PI * 2) * percentageMinutesIntoDay, 0, 0, 1);
}


@end

//
//  Timer.swift
//  Drift
//
//  Created by Mikael Hultgren on 26/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import UIKit

enum Transforming {
    case None
    case StartDateBegin
    case StartDateEnd
    case NowDateBegin
    case NowDateEnd
}

class Timer: UIControl {
    private var updateTimer: NSTimer? = nil

    private var startDate: NSDate? = nil
    private var nowDate: NSDate? = nil
    private var stopDate: NSDate? = nil
    
    private var startTouchPathLayer: CAShapeLayer
    private var startLayer: CAShapeLayer
    private var startPathLayer: CAShapeLayer
    
    private var nowTouchPathLayer: CAShapeLayer
    private var nowLayer: CAShapeLayer
    private var nowPathLayer: CAShapeLayer

    private var secondLayer: CAShapeLayer
    private var secondProgressTicksLayer: CAShapeLayer

    private var deltaDate: NSDate
    private var deltaAngle: CGFloat
    private var deltaTransforming: CATransform3D
    private var deltaLayer: CAShapeLayer
    
    private var previousSecondTick: CGFloat
    private var previousNow: CGFloat
    
    required init(coder aDecoder: NSCoder) {
        drawClockFace()
        
        super.init(coder: aDecoder)
    }
    
    private func drawClockFace() {
        var angle: CGFloat;
    
        if self.layer.respondsToSelector("setContentsScale:") {
            self.layer.contentsScale = UIScreen.mainScreen().scale
        }
        
        // =====================
        // = Ticks initializer =
        // =====================
        let largeTickPath: UIBezierPath = UIBezierPath(rect: CGRectMake(0.0, 0.0, 5.0, 14.0))
        let smallTickPath: UIBezierPath = UIBezierPath(rect: CGRectMake(0.0, 0.0, 3.0, 11.0))
    
        for (NSInteger i = 1; i <= 60; ++i) {
            CAShapeLayer *tick = [CAShapeLayer layer];
            if ([tick respondsToSelector:@selector(setContentsScale:)]) {
                [tick setContentsScale:[[UIScreen mainScreen] scale]];
            }
    
    angle = (CGFloat)((M_PI * 2) / 60.0 * i);
    
    if (i % 15 == 0) {
    // position
    tick.bounds      = CGRectMake(0.0, 0.0, 5.0, self.bounds.size.width / 2 - 30);
    tick.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    tick.anchorPoint = CGPointMake(0.5, 1.0);
    
    // drawing
    tick.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
    tick.fillColor = [[UIColor colorWithWhite:0.167f alpha:1] CGColor];
    tick.lineWidth = 1;
    tick.path      = largeTickPath.CGPath;
    } else {
    // position
    tick.bounds      = CGRectMake(0.0, 0.0, 3.0, self.bounds.size.width / 2.0f - 31.5f);
    tick.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    tick.anchorPoint = CGPointMake(0.5, 1.0);
    
    // drawing
    tick.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
    tick.fillColor = [[UIColor colorWithWhite:0.292f alpha:1] CGColor];
    tick.lineWidth = 1;
    tick.path      = smallTickPath.CGPath;
    }
    
    [self.layer addSublayer:tick];
    }
    
    // ==========================
    // = Now initializer =
    // ==========================
    self.nowLayer = [CAShapeLayer layer];
    if ([self.nowLayer respondsToSelector:@selector(setContentsScale:)]) {
    [self.nowLayer setContentsScale:[[UIScreen mainScreen] scale]];
    }
    
    // We make the bounds larger for the hit test, otherwise the target is
    // to damn small for human hands, martians not included
    UIBezierPath *nowPath = [UIBezierPath bezierPath];
    [nowPath moveToPoint:CGPointMake(25, 17)];   // Start at the bottom
    [nowPath addLineToPoint:CGPointMake(20, 0)];  // Move to top left
    [nowPath addLineToPoint:CGPointMake(30, 0)]; // Move to top right
    
    self.nowPathLayer = [CAShapeLayer layer];
    if ([self.nowPathLayer respondsToSelector:@selector(setContentsScale:)]) {
    [self.nowPathLayer setContentsScale:[[UIScreen mainScreen] scale]];
    }
    self.nowPathLayer.frame = CGRectMake(0, 0, 50, 50);
    
    // drawing
    self.nowPathLayer.fillColor = [[UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:1] CGColor];
    self.nowPathLayer.lineWidth = 1.0;
    self.nowPathLayer.path      = nowPath.CGPath;
    
    // touch path
    UIBezierPath *nowTouchPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(-50, -50, 150, 150)];
    
    self.nowTouchPathLayer = [CAShapeLayer layer];
    if ([self.nowTouchPathLayer respondsToSelector:@selector(setContentsScale:)]) {
    [self.nowTouchPathLayer setContentsScale:[[UIScreen mainScreen] scale]];
    }
    self.nowTouchPathLayer.frame = CGRectMake(-10, -30, 70, 70);
    
    self.nowTouchPathLayer.fillColor   = [[UIColor clearColor] CGColor];
    self.nowTouchPathLayer.strokeColor = [[UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:0.5f] CGColor];
    self.nowTouchPathLayer.strokeEnd   = 0.0;
    self.nowTouchPathLayer.lineWidth   = 6.0;
    self.nowTouchPathLayer.path        = nowTouchPath.CGPath;
    
    // position
    self.nowLayer.bounds      = CGRectMake(0.0, 0.0, 50, self.bounds.size.width / 2.0f - 10);
    self.nowLayer.anchorPoint = CGPointMake(0.5, 1.0);
    self.nowLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.nowLayer.transform   = CATransform3DMakeRotation(0, 0, 0, 1);
    
    [self.nowLayer addSublayer:self.nowPathLayer];
    [self.nowLayer addSublayer:self.nowTouchPathLayer];
    [self.layer addSublayer:self.nowLayer];
    
    // =========================
    // = Start initializer =
    // =========================
    self.startLayer = [CAShapeLayer layer];
    if ([self.startLayer respondsToSelector:@selector(setContentsScale:)]) {
    [self.startLayer setContentsScale:[[UIScreen mainScreen] scale]];
    }
    
    // We make the bounds larger for the hit test, otherwise the target is
    // to damn small for human hands, martians not included
    UIBezierPath *startPath = [UIBezierPath bezierPath];
    [startPath moveToPoint:CGPointMake(25, 17)];   // Start at the bottom
    [startPath addLineToPoint:CGPointMake(20, 0)];  // Move to top left
    [startPath addLineToPoint:CGPointMake(30, 0)]; // Move to top right
    
    self.startPathLayer = [CAShapeLayer layer];
    if ([self.startPathLayer respondsToSelector:@selector(setContentsScale:)]) {
    [self.startPathLayer setContentsScale:[[UIScreen mainScreen] scale]];
    }
    self.startPathLayer.frame = CGRectMake(0, 0, 50, 50);
    
    // drawing
    self.startPathLayer.fillColor = [[UIColor colorWithRed:0.941f green:0.686f blue:0.314f alpha:1] CGColor];
    self.startPathLayer.lineWidth = 1.0;
    self.startPathLayer.path      = startPath.CGPath;
    
    // touch path
    UIBezierPath *startTouchPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(-50, -50, 150, 150)];
    
    self.startTouchPathLayer = [CAShapeLayer layer];
    if ([self.startTouchPathLayer respondsToSelector:@selector(setContentsScale:)]) {
    [self.startTouchPathLayer setContentsScale:[[UIScreen mainScreen] scale]];
    }
    self.startTouchPathLayer.frame = CGRectMake(-10, -30, 70, 70);
    
    self.startTouchPathLayer.fillColor   = [[UIColor clearColor] CGColor];
    self.startTouchPathLayer.strokeColor = [[UIColor colorWithRed:0.941f green:0.686f blue:0.314f alpha:0.5f] CGColor];
    self.startTouchPathLayer.strokeEnd   = 0.0;
    self.startTouchPathLayer.lineWidth   = 6.0;
    self.startTouchPathLayer.path        = startTouchPath.CGPath;
    
    // position
    self.startLayer.bounds      = CGRectMake(0.0, 0.0, 50, self.bounds.size.width / 2.0f - 10);
    self.startLayer.anchorPoint = CGPointMake(0.5, 1.0);
    self.startLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.startLayer.transform   = CATransform3DMakeRotation(0, 0, 0, 1);
    
    [self.startLayer addSublayer:self.startPathLayer];
    [self.startLayer addSublayer:self.startTouchPathLayer];
    [self.layer addSublayer:self.startLayer];
    
    // ==========================
    // = Second initializer =
    // ==========================
    self.secondLayer = [CAShapeLayer layer];
    if ([self.secondLayer respondsToSelector:@selector(setContentsScale:)]) {
    [self.secondLayer setContentsScale:[[UIScreen mainScreen] scale]];
    }
    
    UIBezierPath *secondHandPath = [UIBezierPath bezierPath];
    [secondHandPath moveToPoint:CGPointMake(3.5, 0)];  // Start at the top
    [secondHandPath addLineToPoint:CGPointMake(0, 7)]; // Move to bottom left
    [secondHandPath addLineToPoint:CGPointMake(7, 7)]; // Move to bottom right
    
    // position
    self.secondLayer.bounds      = CGRectMake(0.0, 0.0, 7.0, self.bounds.size.width / 2.0f - 62);
    self.secondLayer.anchorPoint = CGPointMake(0.5, 1.0);
    self.secondLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    // drawing
    self.secondLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1);
    self.secondLayer.fillColor = [[UIColor colorWithRed:0.843f green:0.306f blue:0.314f alpha:1] CGColor];
    self.secondLayer.lineWidth = 1.0;
    self.secondLayer.path      = secondHandPath.CGPath;
    
    [self.layer addSublayer:self.secondLayer];
    
    // =========================================
    // = Second progress ticks initializer =
    // =========================================
    self.secondProgressTicksLayer = [CAShapeLayer layer];
    if ([self.secondProgressTicksLayer respondsToSelector:@selector(setContentsScale:)]) {
    [self.secondProgressTicksLayer setContentsScale:[[UIScreen mainScreen] scale]];
    }
    
    // position
    self.secondProgressTicksLayer.bounds      = CGRectMake(0.0, 0.0, self.bounds.size.width - 100, self.bounds.size.width - 100);
    self.secondProgressTicksLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.secondProgressTicksLayer.anchorPoint = CGPointMake(0.5, 0.5);
    
    [self.layer addSublayer:self.secondProgressTicksLayer];
    
    UIBezierPath *secondHandTickPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, 3.0, 2.0)];
    for (NSInteger i = 1; i <= 60; ++i) {
    angle = (CGFloat)((M_PI * 2) / 60.0 * i);
    
    CAShapeLayer *tick = [CAShapeLayer layer];
    if ([tick respondsToSelector:@selector(setContentsScale:)]) {
    [tick setContentsScale:[[UIScreen mainScreen] scale]];
    }
    
    // position
    tick.bounds      = CGRectMake(0.0, 0.0, 3.0, self.secondProgressTicksLayer.bounds.size.width / 2);
    tick.position    = CGPointMake(CGRectGetMidX(self.secondProgressTicksLayer.bounds), CGRectGetMidY(self.secondProgressTicksLayer.bounds));
    tick.anchorPoint = CGPointMake(0.5, 1.0);
    
    // drawing
    tick.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
    tick.fillColor = [[UIColor colorWithRed:0.843f green:0.306f blue:0.314f alpha:1] CGColor];
    tick.lineWidth = 1;
    tick.path      = secondHandTickPath.CGPath;
    
    [self.secondProgressTicksLayer addSublayer:tick];
    }
    }

    func initWithStartDate(startDate: NSDate, stopDate: NSDate?) {
        reset()
        
        self.startDate = startDate
//        drawStart()

        
    }
    
    func paus(){
        
    }
    
    func stop(){
        
    }
    
    func reset(){
        
    }
}

//
//  EventViewController.swift
//  Drift
//
//  Created by Mikael Hultgren on 02/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import UIKit
import CoreData
import JSQCoreDataKit

let eventViewControllerContext = UnsafeMutablePointer<()>()

class EventViewController: UIViewController {
    // MARK: IBOutlet
    @IBOutlet var eventTimerControl: EventTimerControl?
    @IBOutlet var toggleStartStopButton: UIButton?
    
    @IBOutlet var eventStartTime: UILabel?
    @IBOutlet var eventStartDay: UILabel?
    @IBOutlet var eventStartMonth: UILabel?
    @IBOutlet var eventStartYear: UILabel?
    
    @IBOutlet var eventTimeHours: UILabel?
    @IBOutlet var eventTimeMinutes: UILabel?
    
    @IBOutlet var eventStopTime: UILabel?
    @IBOutlet var eventStopDay: UILabel?
    @IBOutlet var eventStopMonth: UILabel?
    @IBOutlet var eventStopYear: UILabel?
    
    @IBOutlet var tag: UIButton?
    
    // MARK: Private properties
    var shortStandaloneMonthSymbols: NSArray?
    var selectedEvent: Event?
    var stack: CoreDataStack?
    let state: State = State()
    
    let transitionOperator = TransitionOperator()
    
    let calendar = NSCalendar.autoupdatingCurrentCalendar()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bundle = NSBundle(identifier: "com.artsoftheinsane.Drift")
        let model = CoreDataModel(name: "CoreDataModel", bundle: bundle!)
        self.stack = CoreDataStack(model: model)

        self.shortStandaloneMonthSymbols = NSDateFormatter().shortStandaloneMonthSymbols
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.eventTimerControl?.addObserver(self, forKeyPath: "startDate", options: .New, context: eventViewControllerContext)
        self.eventTimerControl?.addObserver(self, forKeyPath: "nowDate", options: .New, context: eventViewControllerContext)
        self.eventTimerControl?.addObserver(self, forKeyPath: "transforming", options: .New, context: eventViewControllerContext)

        if let guid = self.state.selectedEventGUID,
            let moc = self.stack?.managedObjectContext,
            let entity = NSEntityDescription.entityForName(Event.entityName(), inManagedObjectContext: moc) {
                let request = FetchRequest<Event>(entity: entity)
                let result = findByAttribute("guid", withValue: guid, inContext: moc, withRequest: request)
            
                if result.success {
                    let event = result.objects[0]
                    selectedEvent = event
                        
                    self.eventTimerControl?.initWithStartDate(event.startDate, andStopDate: event.stopDate)
                        
                    if event.isActive() {
                        self.toggleStartStopButton?.setTitle("STOP", forState: .Normal)
                        self.animateStartEvent()
                    } else {
                        self.toggleStartStopButton?.setTitle("START", forState: .Normal)
                        self.animateStopEvent()
                    }
                } else {
                    println("*** ERROR: [\(__LINE__)] \(__FUNCTION__) Error while executing fetch request: \(result.error)")
                }
        } else {
            self.selectedEvent = nil
        }
        
        if let name = self.selectedEvent?.inTag?.name,
            let font = UIFont(name: "Helvetica Neue", size: 14) {
                let attriString = NSAttributedString(string:name, attributes:
                    [NSFontAttributeName: font])
            
                self.tag?.setAttributedTitle(attriString, forState: .Normal)
        } else if let font = UIFont(name: "FontAwesome", size: 20) {
            let attriString = NSAttributedString(string:"\u{f02b}", attributes:
                [NSFontAttributeName: font])
            
            self.tag?.setAttributedTitle(attriString, forState: .Normal)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.eventTimerControl?.paus()
        self.eventTimerControl?.removeObserver(self, forKeyPath: "startDate", context: eventViewControllerContext)
        self.eventTimerControl?.removeObserver(self, forKeyPath: "nowDate", context: eventViewControllerContext)
        self.eventTimerControl?.removeObserver(self, forKeyPath: "transforming", context: eventViewControllerContext)
    }
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        super.prepareForSegue(segue, sender: sender)
//        if segue.identifier == "segueToTagsFromEvent",
//            let controller = segue.destinationViewController as? TagsViewController {
//                controller.didDismiss = {
//                    dispatch_async(dispatch_get_main_queue(), { [unowned self] in
//                        self.dismissViewControllerAnimated(true, completion: nil)
//                        })
//                }
//        } else
//    if segue.identifier == "segueToMenuFromEvent",
//            let controller = segue.destinationViewController as? UIViewController {
//                controller.transitioningDelegate = self.transitionOperator
//        }
//    }
    
    private func animateButton(button: UIButton) {
        var pathFrame: CGRect = CGRectMake(-CGRectGetMidY(button.bounds), -CGRectGetMidY(button.bounds), button.bounds.size.height, button.bounds.size.height)
        var path: UIBezierPath = UIBezierPath(roundedRect: pathFrame, cornerRadius:pathFrame.size.height / 2)
        
        var shapePosition: CGPoint = self.view.convertPoint(button.center, fromView:button.superview)
        
        var circleShape: CAShapeLayer = CAShapeLayer.new()
        circleShape.path        = path.CGPath;
        circleShape.position    = shapePosition;
        circleShape.fillColor   = UIColor.clearColor().CGColor
        circleShape.opacity     = 0;
        circleShape.strokeColor = button.titleLabel?.textColor.CGColor;
        circleShape.lineWidth   = 2;
        
        self.view.layer.addSublayer(circleShape)
        
        var scaleAnimation: CABasicAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
        scaleAnimation.toValue   = NSValue(CATransform3D:CATransform3DMakeScale(3, 3, 1))
        
        var alphaAnimation: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
        alphaAnimation.fromValue = 1;
        alphaAnimation.toValue   = 0;
        
        var animation: CAAnimationGroup = CAAnimationGroup.new()
        animation.delegate = self
        animation.animations     = [scaleAnimation, alphaAnimation]
        animation.duration       = 0.5
        
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        circleShape.addAnimation(animation, forKey: nil)
    }
    
    private func updateStartLabelWithDate(date: NSDate) {
        let unitFlags: NSCalendarUnit = .CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitHour | .CalendarUnitMinute

        let components: NSDateComponents = self.calendar.components(unitFlags, fromDate: date)
        
        self.eventStartTime?.text  = String(format: "%02ld:%02ld", components.hour, components.minute)
        self.eventStartDay?.text  = String(format: "%02ld", components.day)
        self.eventStartYear?.text  = String(format: "%04ld", components.year)
        let index = components.month - 1
        if let month = self.shortStandaloneMonthSymbols?.objectAtIndex(index) as? String {
            self.eventStartMonth?.text  = month
        }
    }
    
    private func updateEventTimeFromDate(fromDate: NSDate, toDate: NSDate) {
        let unitFlags: NSCalendarUnit = .CalendarUnitHour | .CalendarUnitMinute
        let components: NSDateComponents = self.calendar.components(unitFlags, fromDate: fromDate, toDate: toDate, options: nil)
        
        let hour: Int = abs(components.hour)
        let minute: Int = abs(components.minute)
        
        var eventTimeHours: String = String(format:"%02ld", hour)
        if components.hour < 0 || components.minute < 0 {
            eventTimeHours = String(format:"-%@", eventTimeHours)
        }
        
        self.eventTimeHours?.text   = eventTimeHours
        self.eventTimeMinutes?.text = String(format:"%02ld", minute)
    }
    
    private func updateStopLabelWithDate(date: NSDate) {
        let unitFlags: NSCalendarUnit = .CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitHour | .CalendarUnitMinute
        
        let components: NSDateComponents = self.calendar.components(unitFlags, fromDate: date)
        
        self.eventStopTime?.text  = String(format: "%02ld:%02ld", components.hour, components.minute)
        self.eventStopDay?.text  = String(format: "%02ld", components.day)
        self.eventStopYear?.text  = String(format: "%04ld", components.year)
        let index = components.month - 1
        if let month = self.shortStandaloneMonthSymbols?.objectAtIndex(index) as? String {
            self.eventStopMonth?.text  = month
        }
    }
    
    private func animateStartEvent() {
        UIView.animateWithDuration(0.3, delay: 0.3, options: .CurveEaseIn, animations: { () -> Void in
            self.eventStartTime?.alpha = 1
            self.eventStartDay?.alpha = 1
            self.eventStartMonth?.alpha = 1
            self.eventStartYear?.alpha = 1
            
            self.eventStopTime?.alpha = 0.2
            self.eventStopDay?.alpha = 0.2
            self.eventStopMonth?.alpha = 1
            self.eventStopYear?.alpha = 1
        }, completion: nil)
    }

    private func animateStopEvent() {
        UIView.animateWithDuration(0.3, delay: 0.3, options: .CurveEaseIn, animations: { () -> Void in
            self.eventStartTime?.alpha = 0.2
            self.eventStartDay?.alpha = 0.2
            self.eventStartMonth?.alpha = 1
            self.eventStartYear?.alpha = 1
            
            self.eventStopTime?.alpha = 1
            self.eventStopDay?.alpha = 1
            self.eventStopMonth?.alpha = 1
            self.eventStopYear?.alpha = 1
            }, completion: nil)
    }
    
    private func animateEventTransforming(eventTimerTransformingEnum: EventTimerTransformingEnum) {
        UIView.animateWithDuration(0.3, delay: 0.3, options: .CurveEaseIn, animations: { () -> Void in
            
            var eventStartAlpha: CGFloat = 1
            var eventStopAlpha: CGFloat = 1
            var eventTimeAlpha: CGFloat = 1
            var eventStartMonthYearAlpha: CGFloat = 1
            var eventStopMonthYearAlpha: CGFloat = 1
            
            switch eventTimerTransformingEnum {
            case .StartDateTransformingStart:
                eventStartAlpha = 1
                eventStartMonthYearAlpha = 1
                
                eventStopAlpha = 0.2
                eventStopMonthYearAlpha = 0.2
                
                eventTimeAlpha = 0.2
            case .StartDateTransformingStop:
                if let active = self.selectedEvent?.isActive() {
                    eventStartAlpha = 1
                    eventStopAlpha = 0.2
                } else {
                    eventStartAlpha = 0.2
                    eventStopAlpha = 1
                }
                eventStartMonthYearAlpha = 1
                eventStopMonthYearAlpha = 1
                
                eventTimeAlpha = 1
            case .NowDateTransformingStart:
                eventStartAlpha = 0.2
                eventStartMonthYearAlpha = 0.2
                
                eventStopAlpha = 1
                eventStopMonthYearAlpha = 1
                
                eventTimeAlpha = 0.2
            case .NowDateTransformingStop:
                if let active = self.selectedEvent?.isActive() {
                    eventStartAlpha = 1
                    eventStopAlpha = 0.2
                } else {
                    eventStartAlpha = 0.2
                    eventStopAlpha = 1
                }
                
                eventStartMonthYearAlpha = 1
                eventStopMonthYearAlpha = 1
                
                eventTimeAlpha = 1
            default:
                break
            }
            
            self.eventStartDay?.alpha = eventStartAlpha
            self.eventStartMonth?.alpha = eventStartMonthYearAlpha
            self.eventStartTime?.alpha = eventStartAlpha
            self.eventStartYear?.alpha = eventStartMonthYearAlpha
            
            self.eventStopDay?.alpha = eventStopAlpha
            self.eventStopMonth?.alpha = eventStopMonthYearAlpha
            self.eventStopTime?.alpha = eventStopAlpha
            self.eventStopYear?.alpha = eventStopMonthYearAlpha
            
            self.eventTimeHours?.alpha = eventTimeAlpha
            self.eventTimeMinutes?.alpha = eventTimeAlpha
            
            }, completion: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == eventViewControllerContext,
            let rawValue = change[NSKeyValueChangeKindKey] as? UInt,
            let changeKindKey = NSKeyValueChange(rawValue: rawValue) where changeKindKey == .Setting {
                
                switch keyPath {
                case "startDate":
                    if let newValue = change[NSKeyValueChangeNewKey] as? NSDate {
                        self.updateStartLabelWithDate(newValue)
                        
                        if let toDate = self.eventTimerControl?.nowDate {
                            self.updateEventTimeFromDate(newValue, toDate: toDate)
                        }
                    }
                case "nowDate":
                    if let newValue = change[NSKeyValueChangeNewKey] as? NSDate {
                        self.updateStopLabelWithDate(newValue)
                        
                        if let fromDate = self.eventTimerControl?.startDate {
                            self.updateEventTimeFromDate(fromDate, toDate: newValue)
                        }
                    }
                case "transforming":
                    if let transforming = change[NSKeyValueChangeNewKey] as? EventTimerTransformingEnum {
                        
                        switch transforming {
                        case .NowDateTransformingStart, .StartDateTransformingStart:
                            self.animateEventTransforming(transforming)
                        case .NowDateTransformingStop:
                            self.animateEventTransforming(transforming)
                            self.selectedEvent?.stopDate = self.eventTimerControl?.nowDate
                            
                            if let moc = self.stack?.managedObjectContext {
                                saveContextAndWait(moc)
                            }
                        case .StartDateTransformingStop:
                            self.animateEventTransforming(transforming)
                            if let startDate = self.eventTimerControl?.startDate {
                                self.selectedEvent?.startDate = startDate
                                
                                if let moc = self.stack?.managedObjectContext {
                                    saveContextAndWait(moc)
                                }
                            }
                        default:
                            break
                        }
                    }
                default:
                    break
                }
        }
    }
    
    @IBAction func showTags(sender: UIButton) {
        if self.selectedEvent != nil {
            self.animateButton(sender)
            self.performSegueWithIdentifier("segueToTagsFromEvent", sender: self)
        }
    }
    
    @IBAction func toggleEventTouchUpInside(sender: UIButton) {
        if let isActive = self.selectedEvent?.isActive() where isActive == true {
            self.eventTimerControl?.stop()
            self.selectedEvent?.stopDate = self.eventTimerControl?.nowDate
            
            self.toggleStartStopButton?.setTitle("START", forState: .Normal)
            self.animateStopEvent()
        } else if let moc = self.stack?.managedObjectContext {
                let event = Event(moc, startDate: NSDate())
                self.selectedEvent = event
                    
                self.state.selectedEventGUID = event.guid
                    
                self.eventTimerControl?.initWithStartDate(event.startDate, andStopDate: event.stopDate)
                    
                self.toggleStartStopButton?.setTitle("STOP", forState: .Normal)
                    
                self.animateStartEvent()
                    
                if let font = UIFont(name: "FontAwesome", size: 20) {
                    let attriString = NSAttributedString(string:"\u{f02b}", attributes:
                        [NSFontAttributeName: font])
                        
                    self.tag?.setAttributedTitle(attriString, forState: .Normal)
                }
        }
        
        self.animateButton(sender)
        
        if let moc = self.stack?.managedObjectContext {
            saveContextAndWait(moc)
        }
    }
}
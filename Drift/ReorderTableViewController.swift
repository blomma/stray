//
//  ReorderTableViewController.swift
//  Drift
//
//  Created by Mikael Hultgren on 2014-09-05.
//  Copyright (c) 2014 Artsoftheinsane. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol ReorderTableViewControllerDelegate : class {
    func canMoveCellAtIndexPath(indexPath:NSIndexPath) -> Bool
    func willBeginMovingCellAtIndexPath(indexPath:NSIndexPath)
    func movedCellFromIndexPath(fromIndexPath:NSIndexPath, toIndexPath:NSIndexPath)
    func didMoveCellToIndexPath(toIndexPath:NSIndexPath)
}

public class ReorderTableViewController : NSObject, UIGestureRecognizerDelegate {
    public weak var delegate:ReorderTableViewControllerDelegate?

    private let SnapshotZoomScale:CGFloat = 1.1
    private let MinLongPressDuration:CFTimeInterval = 0.30
    private let ZoomAnimationDuration:NSTimeInterval = 0.20

    private var longPressRecognizer:UILongPressGestureRecognizer?
    private weak var tableView:UITableView?
    private var snapshotView:UIView?
    
    private var previousIndexPath:NSIndexPath?
    
    private var movingTimer:NSTimer?
    private var scrollingRate:CGFloat?
    
    
    init(tableView:UITableView) {
        super.init()
        
        self.tableView = tableView;
        
        self.longPressRecognizer = UILongPressGestureRecognizer(target:self, action:"didRecognizeLongPress:")
        self.longPressRecognizer?.minimumPressDuration = MinLongPressDuration
        self.longPressRecognizer?.delegate = self;

        self.tableView?.addGestureRecognizer(self.longPressRecognizer!)
    }
    
    func didRecognizeLongPress(recognizer:UILongPressGestureRecognizer) {
        var location = recognizer.locationInView(self.tableView)
        
        if recognizer.state == .Began {
            if let tableView = self.tableView? {
                if let indexPath = tableView.indexPathForRowAtPoint(location) {
                    var rect = tableView.rectForRowAtIndexPath(indexPath)

                    if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                        var size = cell.bounds.size
                        UIGraphicsBeginImageContextWithOptions(size, false, 0)
                        cell.layer.renderInContext(UIGraphicsGetCurrentContext())
                        var cellImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        
                        self.snapshotView = UIImageView(image: cellImage)
                    }
                    
                    if let snapshotView = self.snapshotView {
                        snapshotView.frame = CGRectOffset(snapshotView.bounds, rect.origin.x, rect.origin.y);
                        tableView.addSubview(snapshotView)
                        
                        UIView.animateWithDuration(ZoomAnimationDuration, animations: { () -> Void in
                            snapshotView.transform = CGAffineTransformMakeScale(self.SnapshotZoomScale, self.SnapshotZoomScale)
                            snapshotView.center = CGPointMake(tableView.center.x, location.y)
                            snapshotView.alpha = 0.65
                        })
                        
                        self.delegate?.willBeginMovingCellAtIndexPath(indexPath)
                        
                        self.movingTimer = NSTimer(timeInterval: 0,
                            target: self,
                            selector: "scrollTable",
                            userInfo: nil,
                            repeats: true
                        )
                        
                        NSRunLoop.mainRunLoop().addTimer(self.movingTimer!, forMode: NSDefaultRunLoopMode)
                        
                        self.previousIndexPath = indexPath;
                    }
                }
            }
        } else if recognizer.state == .Changed {
            if let tableView = self.tableView? {
                self.snapshotView?.center = CGPointMake(tableView.center.x, location.y);
                
                var indexPath = tableView.indexPathForRowAtPoint(location)
                if (indexPath != nil && self.previousIndexPath != nil && !self.previousIndexPath!.isEqual(indexPath)) {
                    self.delegate?.movedCellFromIndexPath(previousIndexPath!, toIndexPath: indexPath!)
                }
                
                var rect = tableView.bounds
                
                // We needed to compensate actual contentOffset.y to get the relative y position of touch.
                location.y -= tableView.contentOffset.y
                
                var count = tableView.numberOfRowsInSection(0)
                var cellHeight = tableView.bounds.size.height / CGFloat(count)
                
                var bottomDiff = location.y - (rect.size.height - cellHeight)
                
                if bottomDiff > 0 {
                    self.scrollingRate = bottomDiff / cellHeight
                } else if location.y <= cellHeight {
                    self.scrollingRate = -(cellHeight - max(location.y, 0)) / cellHeight
                } else {
                    self.scrollingRate = nil
                }
                
                self.previousIndexPath = indexPath;
            }
        } else if recognizer.state == .Ended {
            if let tableView = self.tableView? {
                self.snapshotView?.center = CGPointMake(tableView.center.x, location.y)
                
                var indexPath = tableView.indexPathForRowAtPoint(location)
                
                // Check if the cell being moved is above the first cell or below the last
                if indexPath == nil {
                    var count = tableView.numberOfRowsInSection(0)
                    var cellHeight = tableView.bounds.size.height / CGFloat(count)
                    
                    if location.y > CGFloat(count) * cellHeight {
                        indexPath = NSIndexPath(forRow: count - 1, inSection: 0)
                    } else if location.y <= 0 {
                        indexPath = NSIndexPath(forRow: 0, inSection: 0)
                    }
                }
                
                self.scrollingRate = nil
                self.movingTimer?.invalidate()
                
                var rect = tableView.rectForRowAtIndexPath(indexPath!)
                
                UIView.animateWithDuration(ZoomAnimationDuration, animations: { () -> Void in
                    self.snapshotView?.transform = CGAffineTransformIdentity;
                    self.snapshotView?.center = CGPoint(x:CGRectGetMidX(rect), y:CGRectGetMidY(rect))
                    self.snapshotView?.alpha = 1;
                    }, completion: { (Bool finished) -> Void in
                        self.snapshotView?.removeFromSuperview()
                        self.snapshotView = nil
                        
                        self.delegate?.didMoveCellToIndexPath(indexPath!)
                        
                        self.previousIndexPath = nil;
                })
            }
        }
    }
    
    func scrollTable() {
        if self.scrollingRate == nil {
            return
        }
        
        if let tableView = self.tableView? {
            var scrollingRate = self.scrollingRate!
            
            // Scroll tableview while touch point is on top or bottom part
            var location = self.longPressRecognizer!.locationInView(self.tableView)
            var currentOffset = tableView.contentOffset
            
            var newOffset = CGPointMake(currentOffset.x, currentOffset.y + scrollingRate)
            if newOffset.y < 0 {
                newOffset.y = 0
            } else if tableView.contentSize.height < tableView.frame.size.height {
                newOffset = currentOffset
            } else if newOffset.y > tableView.contentSize.height - tableView.frame.size.height {
                newOffset.y = tableView.contentSize.height - tableView.frame.size.height
            }
            
            if currentOffset.y != newOffset.y {
                tableView.contentOffset = newOffset
                
                self.snapshotView?.center = CGPointMake(tableView.center.x, location.y);
                
                var indexPath = tableView.indexPathForRowAtPoint(location)
                if (indexPath != nil && self.previousIndexPath != nil && !self.previousIndexPath!.isEqual(indexPath)) {
                    self.delegate?.movedCellFromIndexPath(previousIndexPath!, toIndexPath: indexPath!)
                }
                
                self.previousIndexPath = indexPath
            }
        }
    }
}

typealias GestureRecognizerDelegate = ReorderTableViewController

extension GestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        var location = gestureRecognizer.locationInView(self.tableView)

        var shouldBegin:Bool? = true
        if let tableView = self.tableView? {
            if let indexPath = tableView.indexPathForRowAtPoint(location) {
                shouldBegin = self.delegate?.canMoveCellAtIndexPath(indexPath)
            }
        }
        
        return shouldBegin!
    }
}
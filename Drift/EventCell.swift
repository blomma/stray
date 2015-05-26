//
//  EventCell.swift
//  Drift
//
//  Created by Mikael Hultgren on 2014-10-04.
//  Copyright (c) 2014 Artsoftheinsane. All rights reserved.
//

import UIKit

@objc public protocol EventCellDelegate : class {
    func didDeleteEventCell(cell:EventCell)
    func didPressTag(cell:EventCell)
}

public class EventCell: UITableViewCell {
    @IBOutlet var frontView: UIView!
    @IBOutlet var frontViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var frontViewTrailingConstraint: NSLayoutConstraint!

    @IBOutlet var eventStartTime: UILabel!
    @IBOutlet var eventStartDay: UILabel!
    @IBOutlet var eventStartMonth: UILabel!
    @IBOutlet var eventStartYear: UILabel!

    @IBOutlet var eventTimeHours: UILabel!
    @IBOutlet var eventTimeMinutes: UILabel!

    @IBOutlet var eventStopTime: UILabel!
    @IBOutlet var eventStopDay: UILabel!
    @IBOutlet var eventStopMonth: UILabel!
    @IBOutlet var eventStopYear: UILabel!

    @IBOutlet var rightSelected: UIView!
    @IBOutlet var tagButton: UIButton!

    public weak var delegate:EventCellDelegate?

    override public func awakeFromNib() {
        super.awakeFromNib()
    }

    override public func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        var backgroundColor: UIColor = selected ? UIColor(white: 0.251, alpha: 1) : UIColor.clearColor()
        if animated {
            var animation: CABasicAnimation = CABasicAnimation(keyPath: "backgroundColor")
            animation.fromValue = self.rightSelected?.backgroundColor?.CGColor
            animation.toValue = backgroundColor.CGColor
            animation.duration = 0.4

            self.rightSelected?.layer.addAnimation(animation, forKey: "backgroundColor")
        }

        self.rightSelected?.layer.backgroundColor = backgroundColor.CGColor
    }

    override public func prepareForReuse() {
        self.frontViewLeadingConstraint?.constant = 0
        self.frontViewTrailingConstraint?.constant = 0
    }

    // IBActions
    @IBAction func editTag(sender: UIButton, forEvent event: UIEvent) {
        self.delegate?.didPressTag(self)
    }
}

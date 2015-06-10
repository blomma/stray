//
//  EventCell.swift
//  Drift
//
//  Created by Mikael Hultgren on 2014-10-04.
//  Copyright (c) 2014 Artsoftheinsane. All rights reserved.
//

import UIKit

protocol EventCellDelegate : class {
    func didDeleteEventCell(cell:EventCell)
    func didPressTag(cell:EventCell)
}

class EventCell: UITableViewCell {
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

    @IBOutlet var selectedMark: UIView!
    @IBOutlet var tagButton: UIButton!

	weak var delegate:EventCellDelegate?

	override func prepareForReuse() {
		selectedMark.alpha = 0
	}

    // IBActions
    @IBAction func editTag(sender: UIButton, forEvent event: UIEvent) {
        self.delegate?.didPressTag(self)
    }
}

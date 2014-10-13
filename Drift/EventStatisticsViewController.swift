//
//  EventStatisticsViewController.swift
//  Drift
//
//  Created by Mikael Hultgren on 2014-10-08.
//  Copyright (c) 2014 Artsoftheinsane. All rights reserved.
//

import UIKit

class EventStatisticsViewController: UIViewController {
    @IBOutlet var startDatePickerBottomConstraint: NSLayoutConstraint!
    @IBOutlet var endDatePickerBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var startDateContainer: UIView!
    @IBOutlet weak var endDateContainer: UIView!

    var startDateShown: Bool = false
    var endDateShow: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func chooseStartDate(sender: UIButton, forEvent event: UIEvent) {
        if startDateShown {
            startDateContainer.addConstraint(startDatePickerBottomConstraint)
        } else {
            startDateContainer.removeConstraint(startDatePickerBottomConstraint)
        }
        
        startDateShown = !startDateShown
        
        UIView.animateWithDuration(0.7, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func chooseEndDate(sender: UIButton, forEvent event: UIEvent) {
        if endDateShow {
            endDateContainer.addConstraint(endDatePickerBottomConstraint)
        } else {
            endDateContainer.removeConstraint(endDatePickerBottomConstraint)
        }
        
        endDateShow = !endDateShow
        
        UIView.animateWithDuration(0.7, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

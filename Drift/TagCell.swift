//
//  TagCell.swift
//  Drift
//
//  Created by Mikael Hultgren on 2014-10-04.
//  Copyright (c) 2014 Artsoftheinsane. All rights reserved.
//

import UIKit

@objc public protocol TagCellDelegate : class {
    func didDeleteTagCell(cell:TagCell)
    func didEditTagCell(cell:TagCell)
}

public class TagCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet var tagName: UILabel?
    @IBOutlet var tagNameTextField:UITextField?
    @IBOutlet var frontView: UIView?
    @IBOutlet var frontViewLeadingConstraint: NSLayoutConstraint?
    @IBOutlet var frontViewTrailingConstraint: NSLayoutConstraint?
    
    @IBOutlet var backViewToTagNameTextFieldConstraint: NSLayoutConstraint?
    @IBOutlet var frontViewLeftSeparatorConstraint: NSLayoutConstraint?
    @IBOutlet var rightSelected: UIView?
    @IBOutlet var deleteButton: UIButton?

    public weak var delegate:TagCellDelegate?

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
    
    // Public methods
    public func setTitle(title: String?) {
        if let t = title? {
            self.tagNameTextField?.text = t.uppercaseString
            self.tagName?.text = t.uppercaseString
            self.tagName?.textColor = UIColor(white: 0.267, alpha: 1)
        } else {
            self.tagNameTextField?.text = ""
            self.tagName?.text = "Swipe ⇢ to name"
            self.tagName?.textColor = UIColor(white: 0.267, alpha: 0.4)
        }
    }
    
    // IBActions
    @IBAction func deleteTag(sender: UIButton, forEvent event: UIEvent) {
        self.delegate?.didDeleteTagCell(self)
    }
}

typealias TextFieldDelegate = TagCell

extension TextFieldDelegate {
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }
    
    public func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return true
    }
    
    public func textFieldDidEndEditing(textField: UITextField) {
        textField.resignFirstResponder()
        
        self.delegate?.didEditTagCell(self)
    }
}
//
//  FDRightDetailWithTextFieldCell.swift
//  Echo
//
//  Created by William Entriken on 1/11/16.
//
//

//TODO: put this motherfucker straight into CocoaPods

import Foundation
import UIKit

class FDRightDetailWithTextFieldCell: UITableViewCell {
    var textField: UITextField!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    func setup() {
        self.detailTextLabel!.hidden = true
        self.contentView.viewWithTag(3)?.removeFromSuperview()
        self.textField = UITextField()
        self.textField.tag = 3
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.textField)
        self.addConstraint(NSLayoutConstraint(item: self.textField, attribute: .Leading, relatedBy: .Equal, toItem: self.contentView, attribute: .Leading, multiplier: 1, constant: 50))
        self.addConstraint(NSLayoutConstraint(item: self.textField, attribute: .Top, relatedBy: .Equal, toItem: self.contentView, attribute: .Top, multiplier: 1, constant: 8))
        self.addConstraint(NSLayoutConstraint(item: self.textField, attribute: .Bottom, relatedBy: .Equal, toItem: self.contentView, attribute: .Bottom, multiplier: 1, constant: -8))
        self.addConstraint(NSLayoutConstraint(item: self.textField, attribute: .Trailing, relatedBy: .Equal, toItem: self.contentView, attribute: .Trailing, multiplier: 1, constant: -16))
        self.textField.textAlignment = .Right
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.textField.becomeFirstResponder()
    }
}
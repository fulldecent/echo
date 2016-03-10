//
//  MBProgressHUD+Flash.swift
//  Echo
//
//  Created by William Entriken on 1/20/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import Foundation
import MBProgressHUD

//TODO: get this accepted upstream
extension MBProgressHUD {
    /// Briefly display an error message with a popover display
    static func flashError(error: NSError) {
        self.flashText(error.localizedDescription)
    }
    
    static func flashText(text: String) {
        let window = UIApplication.sharedApplication().keyWindow!
        MBProgressHUD.hideAllHUDsForView(window, animated: false)
        
        let hud = MBProgressHUD(view: window)
        hud.mode = .CustomView
        hud.removeFromSuperViewOnHide = true
        
        let view: UITextView = UITextView(frame: CGRectMake(0, 0, 200, 200))
        view.text = text
        view.font = hud.labelFont
        view.textColor = UIColor.whiteColor()
        view.backgroundColor = UIColor.clearColor()
        view.sizeToFit()
        
        hud.customView = view
        hud.show(true)
        hud.hide(true, afterDelay: 1.2)
    }
}

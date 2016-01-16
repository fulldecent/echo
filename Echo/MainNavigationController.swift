//
//  MainNavigationController.swift
//  Echo
//
//  Created by Full Decent on 1/14/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import Foundation
import UIKit

class MainNavigationController: UINavigationController {
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "pushNotificationReceived:", name: "pushNotification", object: nil)
        let color = UIColor(red: 244.0 / 255, green: 219.0 / 255, blue: 0, alpha: 1)
        self.navigationBar.tintColor = color
    }

    func pushNotificationReceived(aNotification: NSNotification) {
        self.popToRootViewControllerAnimated(true)
        //TODO this crashes now, not sure what view to show
        self.performSegueWithIdentifier("meetPeople", sender: self)
    }
}
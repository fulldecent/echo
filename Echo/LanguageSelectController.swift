//
//  LanguageSelectController.swift
//  Echo
//
//  Created by William Entriken on 1/10/16.
//
//

import Foundation
import UIKit
import Google

protocol LanguageSelectControllerDelegate: class {
    func languageSelectController(controller: AnyObject, didSelectLanguage tag: String, withNativeName name: String) -> Void
}

class LanguageSelectController: UITableViewController {
    let languages = Languages.languages
    weak var delegate: LanguageSelectControllerDelegate?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "LanguageSelect")
        tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject: AnyObject])
        self.tableView.contentInset = UIEdgeInsetsMake(20, self.tableView.contentInset.left, self.tableView.contentInset.bottom, self.tableView.contentInset.right)
    }
}

extension LanguageSelectController /*: UITableViewDataSource*/ {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.languages.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = "leftDetail"
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier)
        cell!.textLabel!.text = self.languages[indexPath.row].languageTag
        cell!.detailTextLabel!.text = self.languages[indexPath.row].nativeName
        return cell!
    }
}

extension LanguageSelectController /*: UITableViewDelegate*/ {
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.languageSelectController(self, didSelectLanguage: self.languages[indexPath.row].languageTag, withNativeName: self.languages[indexPath.row].nativeName)
        self.dismissViewControllerAnimated(true, completion: { _ in })
    }
}

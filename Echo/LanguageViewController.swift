//
//  LanguageViewController.swift
//  Echo
//
//  Created by Full Decent on 1/15/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import UIKit

protocol LanguageViewControllerDelegate: class {
    func languageViewController(controller: LanguageViewController, didSelect language: Language)
}

protocol LanguageViewControllerDataSource: class {
    func languagesForLanguageViewController(controller: LanguageViewController) -> [Language]
    func selectedLanguageForLanguageViewController(controller: LanguageViewController) -> Language
}

class LanguageViewController: UITableViewController {
    weak var delegate: LanguageViewControllerDelegate?
    weak var dataSource: LanguageViewControllerDataSource?

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource!.languagesForLanguageViewController(controller: self).count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "language", for: indexPath)
        let language = dataSource!.languagesForLanguageViewController(controller: self)[indexPath.row]
        cell.textLabel?.text = language.nativeName()
        if (language == dataSource!.selectedLanguageForLanguageViewController(controller: self)) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let language = dataSource!.languagesForLanguageViewController(controller: self)[indexPath.row]
        self.delegate?.languageViewController(controller: self, didSelect: language)
        self.tableView.reloadData()
    }
}

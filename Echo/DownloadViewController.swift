//
//  DownloadViewController.swift
//  Echo
//
//  Created by Full Decent on 1/15/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import UIKit
import MBProgressHUD
import TDBadgedCell

protocol DownloadViewControllerDelegate: class {
    func downloadViewController(controller: DownloadViewController, downloaded lesson: Lesson)
}

class DownloadViewController: UITableViewController {
    var language = Language.studyingLanguage
    var lessons = [Lesson]()
    weak var delegate: DownloadViewControllerDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem?.title = Language.studyingLanguage.nativeName()
    }
    
    @IBAction func refresh() {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = .indeterminate
        Lesson.lessons(in: language) { lessons in
            hud.removeFromSuperview()
            self.lessons = lessons
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lessons.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "downloadableLesson", for: indexPath) as! TDBadgedCell
        let lesson = lessons[indexPath.row]
        cell.textLabel?.text = lesson.name
        cell.detailTextLabel?.text = lesson.detail
        cell.badgeString = "⭐️ \(lesson.likes)"
        cell.badgeRightOffset = 5.0
        cell.badgeColor = UIColor(hue: 0, saturation: 0, brightness: 0.9, alpha: 1.0)
        cell.badgeTextColor = .black
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard lessons.indices.contains(indexPath.row) else {
            return
        }
        let lessonId = lessons[indexPath.row].id
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = .indeterminate
        Lesson.lesson(withId: lessonId) { lesson in
            hud.removeFromSuperview()
            self.delegate?.downloadViewController(controller: self, downloaded: lesson)
            self.refreshControl?.endRefreshing()
            Achievement.downloadOneLesson.setAccomplished()
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? LanguageViewController {
            controller.delegate = self
            controller.dataSource = self
        }
    }
}

extension DownloadViewController: LanguageViewControllerDataSource {
    func languagesForLanguageViewController(controller: LanguageViewController) -> [Language] {
        return Language.allValues
    }
    
    func selectedLanguageForLanguageViewController(controller: LanguageViewController) -> Language {
        return Language.studyingLanguage
    }
}

extension DownloadViewController: LanguageViewControllerDelegate {
    func languageViewController(controller: LanguageViewController, didSelect language: Language) {
        self.language = language
        Language.studyingLanguage = language
        self.navigationItem.rightBarButtonItem?.title = language.nativeName()
        controller.navigationController!.popViewController(animated: true)
    }
}

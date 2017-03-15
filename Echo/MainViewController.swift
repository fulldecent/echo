//
//  MainViewController.swift
//  Echo
//
//  Created by Full Decent on 1/15/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import UIKit
import MessageUI
import TDBadgedCell
import YTBarButtonItemWithBadge

class MainViewController: UITableViewController {
    let lessonLibrary = LessonLibrary.main

    fileprivate enum Section: Int {
        case myLessons = 0
        case downloadALesson
        case requestALesson
        
        static let allValues: [Section] = [.myLessons, .downloadALesson, .requestALesson]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lessonLibrary.delegate = self

        let buttonWithBadge = YTBarButtonItemWithBadge();
        buttonWithBadge.setHandler {self.performSegue(withIdentifier: "achievement", sender: buttonWithBadge)}
        buttonWithBadge.setTitle(value: "🏆");
        if Achievement.unreadCount() > 0 {
            buttonWithBadge.setBadge(value: "\(Achievement.unreadCount())");
        }
        navigationItem.setRightBarButton(buttonWithBadge.getBarButtonItem(), animated: true);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Swift bug hack
        if let buttonWithBadge = navigationItem.rightBarButtonItems?.first as Any as? YTBarButtonItemWithBadge {
            if Achievement.unreadCount() > 0 {
                buttonWithBadge.setBadge(value: "\(Achievement.unreadCount())");
            } else {
                buttonWithBadge.setBadge(value: nil)
            }
        }
    }

    @IBAction func refresh() {
        tableView.reloadData()
        refreshControl?.endRefreshing()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allValues.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .myLessons:
            return lessonLibrary.lessonsAndStatus.count
        case .downloadALesson:
            return 1
        case .requestALesson:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .myLessons:
            return "My lessons"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch Section(rawValue: indexPath.section)! {
        case .myLessons:
            let (lesson, status) = lessonLibrary.lessonsAndStatus[indexPath.row]
            
            //TODO: -- clean up that cell!
            switch status {
            case .downloading(let progress):
                cell = tableView.dequeueReusableCell(withIdentifier: "lessonDownloading", for: indexPath)
                let prog = cell.contentView.viewWithTag(1) as! UIProgressView
                prog.observedProgress = progress
                return cell
            default:
                break
            }

            
            cell = tableView.dequeueReusableCell(withIdentifier: "lesson", for: indexPath)
            let cell = cell as! TDBadgedCell
            cell.badgeString = lesson.language.rawValue

            cell.textLabel?.text = lesson.name
            cell.detailTextLabel?.text = lesson.detail
            switch status {
            case .usable:
                //cell.detailTextLabel?.text?.append(" USABLE")
                break
            case .notUsable:
                cell.detailTextLabel?.text?.append(" NEEDS TO REDOWNLOAD")
            case .downloading(let progress):
                cell.detailTextLabel?.text?.append(" DOWNLOADING \(progress.fractionCompleted)")
            }
        case .downloadALesson:
            cell = tableView.dequeueReusableCell(withIdentifier: "downloadALesson", for: indexPath)
        case .requestALesson:
            cell = tableView.dequeueReusableCell(withIdentifier: "requestALesson", for: indexPath)
        }
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == Section.myLessons.rawValue {
            return true
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == Section.myLessons.rawValue {
            return .delete
        }
        return .none
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            lessonLibrary.lessonsAndStatus.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .requestALesson:
            if !MFMailComposeViewController.canSendMail() {
                print("Mail services are not available")
                return
            }
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            composeVC.setToRecipients(["echo@phor.net"])
            composeVC.setSubject("New lesson idea")
            composeVC.setMessageBody("Hello,\n\nI have a new lesson to recommend.", isHTML: false)
            self.present(composeVC, animated: true, completion: nil)
        default:
            break
        }
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let downloadVC as DownloadViewController:
            downloadVC.delegate = self
        case let lessonVC as LessonViewController:
            let cell = sender as! UITableViewCell
            let indexPath = tableView.indexPath(for: cell)!
            lessonVC.lesson = lessonLibrary.lessonsAndStatus[indexPath.row].lesson
        default:
            break
        }
    }
}

extension MainViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension MainViewController: DownloadViewControllerDelegate {
    func downloadViewController(controller: DownloadViewController, downloaded lesson: Lesson) {
        lessonLibrary.append(lesson: lesson)
        let section = Section.myLessons.rawValue
        let newIndex = IndexPath(row: lessonLibrary.lessonsAndStatus.count - 1, section: section)
        self.tableView.insertRows(at: [newIndex], with: .fade)
        _ = controller.navigationController?.popViewController(animated: true)
    }
}

extension MainViewController: LessonLibraryDelegate {
    func lessonLibrary(library: LessonLibrary, downloadedLessonWithIndex index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
}

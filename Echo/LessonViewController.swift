//
//  LessonViewController.swift
//  Echo
//
//  Created by Full Decent on 1/15/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import UIKit

class LessonViewController: UITableViewController {

    var lesson: Lesson? = nil {
        didSet {
            tableView.reloadData()
            self.navigationItem.title = "📖 " + lesson!.name
        }
    }
    
    var currentWordIndex: Int? = nil
    
    // MARK: - UIView
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Achievement.startOneLesson.setAccomplished()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (lesson?.words.count ?? 0) + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch indexPath.row {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "shuffle", for: indexPath)
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: "word", for: indexPath)
            let word = lesson!.words[indexPath.row - 1]
            cell.textLabel?.text = word.name
            cell.detailTextLabel?.text = word.detail
        }

        // Configure the cell...

        return cell
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let practiceVC as PracticeViewController:
            let cell = sender as! UITableViewCell
            let indexPath = tableView.indexPath(for: cell)!
            switch indexPath.row {
            case 0:
                currentWordIndex = Int(arc4random_uniform(UInt32(lesson!.words.count)))
            default:
                currentWordIndex = indexPath.row - 1
            }
            practiceVC.word = lesson!.words[currentWordIndex!]
            practiceVC.delegate = self
        default:
            break
        }
    }
}

extension LessonViewController: PracticeViewControllerDelegate {
    func practiceViewControllerDidSkip(controller: PracticeViewController) {
        let wordCount = lesson == nil ? 0 : lesson!.words.count
        switch currentWordIndex {
        case .some(let index) where index < wordCount - 1:
            currentWordIndex = index + 1
            controller.word = lesson?.words[currentWordIndex!]
        case .some(let index) where index == wordCount - 1:
            _ = controller.navigationController?.popViewController(animated: true)
        default:
            currentWordIndex = Int(arc4random_uniform(UInt32(wordCount)))
            controller.word = lesson?.words[currentWordIndex!]
        }
    }
}

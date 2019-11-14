//
//  AchievementsViewController.swift
//  Echo
//
//  Created by Full Decent on 1/15/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import UIKit
import MBProgressHUD
import AVFoundation

class AchievementsViewController: UITableViewController {

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(convertFromAVAudioSessionCategory(AVAudioSession.Category.playAndRecord))
            try audioSession.overrideOutputAudioPort(.speaker)
            try audioSession.setActive(true)
        } catch {
            NSLog("error doing outputaudioportoverride: \(error)")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Achievement.markAllRead()
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Achievement.allValues.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let achievement = Achievement.allValues[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "achievement", for: indexPath)
        cell.textLabel?.text = achievement.rawValue
        cell.accessoryType = .none

        switch achievement {
        case let x where x.isAccomplished():
            cell.textLabel?.text = "✅ " + achievement.rawValue
        case .enableMicrophone:
            cell.accessoryType = .disclosureIndicator
//        case .enableOneWeekReminder:
//            cell.accessoryType = .disclosureIndicator
        default:
            break
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let achievement = Achievement.allValues[indexPath.row]
        switch achievement {
        case .enableMicrophone:
            return indexPath
//        case .enableOneWeekReminder:
//            return indexPath
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let achievement = Achievement.allValues[indexPath.row]
        switch achievement {
        case .enableMicrophone:
            AVAudioSession.sharedInstance().requestRecordPermission {
                granted in
                if granted {
                    Achievement.enableMicrophone.setAccomplished()
                    self.tableView.reloadData()
                }
            }
        default:
            break
        }
    }

    @objc func handleRouteChange(_ notification: Notification) {
        DispatchQueue.main.async {
            let route = AVAudioSession.sharedInstance().currentRoute
            for desc: AVAudioSessionPortDescription in route.outputs {
                if (convertFromAVAudioSessionPort(desc.portType) == convertFromAVAudioSessionPort(AVAudioSession.Port.headphones)) {
                    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                    hud.mode = .text
                    hud.label.text = "🎧"
                    hud.hide(animated: true, afterDelay: 0.3)
                    Achievement.plugInHeadphone.setAccomplished()
                    Achievement.markAllRead()
                    self.tableView.reloadData()
                }
            }
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionPort(_ input: AVAudioSession.Port) -> String {
	return input.rawValue
}

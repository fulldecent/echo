//
//  Achievement.swift
//  Echo
//
//  Created by Full Decent on 1/15/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import Foundation

enum Achievement: String {
    case enableMicrophone = "Enable microphone"
    case plugInHeadphone = "Plug in headphone"
    case downloadOneLesson = "Download one lesson"
    case startOneLesson = "Start one lesson"
    //case enableOneWeekReminder = "Enable one week reminder"
    
    func isAccomplished() -> Bool {
        let storedAchievements = UserDefaults.standard.dictionary(forKey: "achievement")
        return storedAchievements?[self.rawValue] as? Bool ?? false
    }
    
    func isUnread() -> Bool {
        let storedAchievements = UserDefaults.standard.dictionary(forKey: "achievementUnread")
        return storedAchievements?[self.rawValue] as? Bool ?? false
    }
    
    func setAccomplished() {
        let defaults = UserDefaults.standard
        var storedAchievements = defaults.dictionary(forKey: "achievement") ?? [String: Any]()
        storedAchievements[self.rawValue] = true
        defaults.set(storedAchievements, forKey: "achievement")
        var unreadAchievements = defaults.dictionary(forKey: "achievementUnread") ?? [String: Any]()
        unreadAchievements[self.rawValue] = true
        defaults.set(storedAchievements, forKey: "achievement")
        defaults.synchronize()
    }

    static let allValues: [Achievement] = [
        .enableMicrophone,
        .plugInHeadphone,
        .downloadOneLesson,
        .startOneLesson
        //.enableOneWeekReminder
    ]
    
    static func unreadCount() -> Int {
        return allValues.filter { $0.isUnread() }.count
    }
    
    static func markAllRead() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "achievementUnread")
        defaults.synchronize()
    }
}

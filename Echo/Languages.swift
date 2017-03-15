//
//  Languages.swift
//  Echo
//
//  Created by Full Decent on 1/15/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import Foundation

// Language codes from IANA Language Subtag Registry
// Sorted based on number of L1 speakers (need source)

enum Language: String {
    case cmn
    case es
    case en
    case hi
    case ar
    case bn
    case pt
    case ru
    case ja
    case pa
    case de
    case jv
    case wuu
    case mr
    case te
    case vi
    case fr
    case ko
    case ta
    case yue
    case tr
    case ps
    case it
    
    static let allValues: [Language] = [.cmn, .es, .en, .hi, .ar, .bn, .pt, .ru, .ja, .pa, .de, .jv, .wuu, .mr, .te, .vi, .fr, .ko, .ta, .yue, .tr, .ps, .it]

    func nativeName() -> String {
        switch self {
        case .cmn:
            return "中文"
        case .es:
            return "Español"
        case .en:
            return "English"
        case .hi:
            return "हिन्दी, हिंदी"
        case .ar:
            return "العربية"
        case .bn:
            return "বাংলা"
        case .pt:
            return "Português"
        case .ru:
            return "русский язык"
        case .ja:
            return "日本語"
        case .pa:
            return "ਪੰਜਾਬੀ"
        case .de:
            return "Deutsch"
        case .jv:
            return "Basa Jawa"
        case .wuu:
            return "吴语"
        case .mr:
            return "मराठी"
        case .te:
            return "తెలుగు"
        case .vi:
            return "Tiếng Việt"
        case .fr:
            return "Français"
        case .ko:
            return "한국어"
        case .ta:
            return "தமிழ்"
        case .yue:
            return "粵語"
        case .tr:
            return "Türkçe"
        case .ps:
            return "پښتو"
        case .it:
            return "Italiano"
  
        }
    }
    
    static var studyingLanguage: Language {
        get {
            if let storedLanguage = UserDefaults.standard.string(forKey: "studyingLanguage") {
                return Language(rawValue: storedLanguage)!
            }
            return .en
        }
        set (newLanguage) {
            let defaults = UserDefaults.standard
            defaults.set(newLanguage.rawValue, forKey: "studyingLanguage")
            defaults.synchronize()
        }
    }
}

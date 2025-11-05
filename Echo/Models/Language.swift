// Languages.swift
// Echo
//
// Created by Full Decent on 1/15/17.
// Copyright © 2017 William Entriken. All rights reserved.
//
import Foundation

// Language codes from IANA Language Subtag Registry
// Sorted based on number of L1 speakers from
// https://en.wikipedia.org/wiki/List_of_languages_by_number_of_native_speakers
enum Language: String, Codable, CaseIterable {
    case cmn
    case es
    case en
    // case ar
    // case hi
    // case pt
    // case bn
    // case ru
    // case ja
    // case pa
    // case vi
    // case yue
    // case tr
    // case wuu
    // case mr
    // case te
    // case ko
    // case ta
    // case de
    case fr
    // case jv
    // case it
    // case ps
   
    func nativeName() -> String {
        switch self {
        case .cmn:
            return "中文"
        case .es:
            return "Español"
        case .en:
            return "English"
        // case .ar:
            // return "العربية"
        // case .hi:
            // return "हिन्दी, हिंदी"
        // case .pt:
            // return "Português"
        // case .bn:
            // return "বাংলা"
        // case .ru:
            // return "русский язык"
        // case .ja:
            // return "日本語"
        // case .pa:
            // return "ਪੰਜਾਬੀ"
        // case .vi:
            // return "Tiếng Việt"
        // case .yue:
            // return "粵語"
        // case .tr:
            // return "Türkçe"
        // case .wuu:
            // return "吴语"
        // case .mr:
            // return "मराठी"
        // case .te:
            // return "తెలుగు"
        // case .ko:
            // return "한국어"
        // case .ta:
            // return "தமிழ்"
        // case .de:
            // return "Deutsch"
        case .fr:
            return "Français"
        // case .jv:
            // return "Basa Jawa"
        // case .it:
            // return "Italiano"
        // case .ps:
            // return "پښتو"
        }
    }
}

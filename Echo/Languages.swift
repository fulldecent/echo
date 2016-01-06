//
//  Languages.swift
//  Echo
//
//  Created by William Entriken on 1/3/16.
//
//

import Foundation

class Languages: NSObject {
    static var languages: [[String: String]] = {
        let url = NSBundle.mainBundle().URLForResource("Languages", withExtension: "plist")!
        return NSArray(contentsOfURL: url)! as! [[String: String]]
    }()
    
    class func nativeDescriptionForLanguage(langTag: String) -> String {
        for langEntry: [String: String] in languages {
            if langEntry["tag"] == langTag {
                return langEntry["nativeName"]!
            }
        }
        NSLog("language not found")
        return "Language not found"
    }
    
    class func sortedListOfLanguages(langTags: [String]) -> [String] {
        var retval: [String] = [String]()
        for langEntry: [String: String] in languages {
            if langTags.contains(langEntry["tag"]!) {
                retval.append(langEntry["tag"]!)
            }
        }
        return retval
    }
}
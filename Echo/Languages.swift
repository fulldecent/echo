//
//  Languages.swift
//  Echo
//
//  Created by William Entriken on 1/3/16.
//
//

import Foundation

struct Language {
    let languageTag: String // From IANA Language Subtag Registry
    let nativeName: String
}

class Languages {
    static var languages: [Language] = {
        let url = NSBundle.mainBundle().URLForResource("Languages", withExtension: "plist")!
        let theArray = NSArray(contentsOfURL: url)! as! [[String: String]]
        return theArray.map({Language(languageTag: $0["tag"]!, nativeName: $0["nativeName"]!)})
    }()
    
    class func nativeDescriptionForLanguage(langTag: String) -> String {
        for language in languages {
            if language.languageTag == langTag {
                return language.nativeName
            }
        }
        return "Language"
    }
    
    class func sortedListOfLanguages(langTags: [String]) -> [String] {
        var retval = [String]()
        for language in languages {
            if langTags.contains(language.languageTag) {
                retval.append(language.languageTag)
            }
        }
        return retval
    }
}
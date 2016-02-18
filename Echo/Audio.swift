//
//  Audio.swift
//  Echo
//
//  Created by William Entriken on 12/17/15.
//
//

import Foundation

//MAYBE: maybe make this and other model classes into structs?
//MAYBE: maybe replace k- constant strings with an enum https://stackoverflow.com/questions/34781354/how-do-i-keep-configuration-strings-in-swift?noredirect=1#comment57307596_34781354
//MAYBE: maybe replace word property with a directory property for which this object should store its files
public class Audio {
    private enum JSONKey: String {
        case ServerId = "fileID"
        case UUID = "fileCode"
    }
    
    //MAYBE: looser coupling, don't need this
    weak var word: Echo.Word?
    
    public lazy var uuid = NSUUID().UUIDString
    
    public var serverId: Int? = nil {
        didSet {
            guard let oldUrl = self.word?.fileURL()?.URLByAppendingPathComponent(self.uuid) else {
                return
            }
            guard oldUrl.checkResourceIsReachableAndReturnError(nil) else {
                return
            }
            let newUrl = self.word!.fileURL()!.URLByAppendingPathComponent(String(self.serverId))
            do {
                try NSFileManager.defaultManager().moveItemAtURL(oldUrl, toURL: newUrl)
            }
            catch let error as NSError {
                print("Moved failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    public init(word: Word) {
        self.word = word
    }

    public func fileURL() -> NSURL? {
        let base = self.word?.fileURL()
        if self.serverId > 0 {
            return base?.URLByAppendingPathComponent(String(self.serverId))
        }
        return base?.URLByAppendingPathComponent(self.uuid)
    }
    
    public func fileExistsOnDisk() -> Bool {
        guard let url = self.fileURL() else {
            return false
        }
        return url.checkResourceIsReachableAndReturnError(nil)
    }
}
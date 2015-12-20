//
//  Audio.swift
//  Echo
//
//  Created by William Entriken on 12/17/15.
//
//

import Foundation

class Audio: NSObject {
    private let kFileID = "fileID"
    private let kFileCode = "fileCode"
    
    weak var word: Echo.Word?

    lazy var uuid = {
        return NSUUID().UUIDString
    }()
    
    //WARNING
    //TODO THIS NEEDS TO BE NOT OPTIONAL SO IT CAN BE USED IN OBJECTIVE-C
    // temporary fix: 0 means undefined
    var serverId: Int = 0 {
        didSet {
            guard let oldUrl = self.word?.fileURL()?.URLByAppendingPathComponent(self.uuid) else {
                return
            }
            guard oldUrl.checkResourceIsReachableAndReturnError(nil) else {
                return
            }
            let newUrl = self.word!.fileURL()!.URLByAppendingPathComponent(String(self.serverId))
            let fileManager = NSFileManager.defaultManager()
            do {
                try fileManager.moveItemAtURL(oldUrl, toURL: newUrl)
            }
            catch let error as NSError {
                print("Moved failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    init(word: Word) {
        self.word = word
        super.init()
    }

    func fileURL() -> NSURL? {
        let base = self.word?.fileURL()
        if self.serverId > 0 { //TODO temp hack, should test NIL
            return base?.URLByAppendingPathComponent(String(self.serverId))
        }
        return base?.URLByAppendingPathComponent(self.uuid)
    }
    
    func fileExistsOnDisk() -> Bool {
        guard let url = self.fileURL() else {
            return false
        }
        return url.checkResourceIsReachableAndReturnError(nil)
    }
}
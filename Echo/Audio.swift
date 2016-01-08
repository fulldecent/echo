//
//  Audio.swift
//  Echo
//
//  Created by William Entriken on 12/17/15.
//
//

import Foundation

public class Audio: NSObject {
    private let kFileID = "fileID"
    private let kFileCode = "fileCode"
    
    weak var word: Echo.Word?

    public lazy var uuid = {
        return NSUUID().UUIDString
    }()
    
    //TODO: make this an optional instead of arbitrary 0=not on server
    public var serverId: Int = 0 {
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
    
    public init(word: Word) {
        self.word = word
        super.init()
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
//
//  LessonSet.swift
//  Echo
//
//  Created by William Entriken on 1/5/16.
//
//

import Foundation

class LessonSet {
    var name: String
    var lessons = [Lesson]()
    lazy var lessonTransferProgress = [Lesson : NSProgress]()
    
    init(name: String) {
        self.name = name
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let jsons: [String] = defaults.objectForKey("lessons-\(name)") as? [String] {
            for json in jsons {
                if let lesson = Lesson(JSONString: json) {
                    self.lessons.append(lesson)
                }
            }
        }
    }
    
    func writeToDisk() {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        var lessonJsons = [String]()
        for lesson in self.lessons {
            guard let lessonJson = lesson.toJSON() else {
                continue;
            }
            if let lessonJsonSTRING = String(data: lessonJson, encoding: NSUTF8StringEncoding) {
                lessonJsons.append(lessonJsonSTRING)
            }
        }
        defaults.setObject(lessonJsons, forKey: "lessons-\(name)")
    }
    
    func syncStaleLessonsWithProgress(progress: (lesson: Lesson, progress: NSProgress) -> Void) {
        let lessonsToDownload = self.lessons.filter { $0.remoteChangesSinceLastSync && lessonTransferProgress[$0] == nil }
        for lesson in lessonsToDownload {
            lessonTransferProgress[lesson] = NSProgress.discreteProgressWithTotalUnitCount(1000)
            self.pullLessonWithFiles(lesson,
                withProgress: {
                    (closureLesson: Lesson, closureProgress: NSProgress) in
                    self.lessonTransferProgress[closureLesson] = closureProgress
                    progress(lesson: closureLesson, progress: closureProgress)
                    if closureProgress.fractionCompleted == 1 {
                        self.lessonTransferProgress.removeValueForKey(closureLesson)
                        self.writeToDisk()
                    }
                }, onFailure: nil)
        }

        let lessonsToUpload = self.lessons.filter { $0.localChangesSinceLastSync && lessonTransferProgress[$0] == nil }
        for lesson in lessonsToUpload {
            lessonTransferProgress[lesson] = NSProgress.discreteProgressWithTotalUnitCount(1000)
            self.pushLessonWithFiles(lesson,
                withProgress: {
                    (closureLesson: Lesson, closureProgress: NSProgress) in
                    self.lessonTransferProgress[closureLesson] = closureProgress
                    progress(lesson: closureLesson, progress: closureProgress)
                    if closureProgress.fractionCompleted == 1 {
                        self.lessonTransferProgress.removeValueForKey(closureLesson)
                        self.writeToDisk()
                    }
                }, onFailure: nil)
        }
    }
    
    func deleteLesson(lesson: Lesson) {
        lesson.deleteFromDisk()
        self.lessonTransferProgress.removeValueForKey(lesson)
        if let index = self.lessons.indexOf(lesson) {
            self.lessons.removeAtIndex(index)
        }
        self.writeToDisk()
    }
    
    func deleteLessonAndStopSharing(lesson: Lesson, onSuccess success: (() -> Void)?, onFailure failure: ((error: NSError) -> Void)?) {
        let networkManager = NetworkManager.sharedNetworkManager
        networkManager.deleteLessonWithID(lesson.serverId, onSuccess: {
            () -> Void in
            self.deleteLesson(lesson)
            success?()
        }, onFailure: {(theError: NSError!) -> Void in
            failure?(error: theError)
        })
    }
    
    func addOrUpdateLesson(lesson: Lesson) {
        defer {
            self.writeToDisk()
        }
        guard !self.lessons.contains(lesson) else {
            return
        }
        for var itLesson in self.lessons {
            if itLesson.serverId == lesson.serverId {
                itLesson = lesson //TODO: is this actually modifying self.lessons???
                return
            }
        }
        self.lessons.append(lesson)
    }
    
    func setRemoteUpdatesForLessonsWithIDs(newLessonIDs: [Int]) {
        for lesson in self.lessons {
            if newLessonIDs.contains(lesson.serverId) {
                lesson.remoteChangesSinceLastSync = true
            }
        }
        self.writeToDisk()
    }
    
    // TODO: REMOVE LESSON FROM THE CALLBACK!
    private func pullLessonWithFiles(lessonToSync: Lesson,
                                     withProgress progressBlock: ((lesson: Lesson, progress: NSProgress) -> Void)?,
                                     onFailure failureBlock: ((error: NSError) -> Void)?) {
        NSLog("WANT TO PULL LESSON: %ld", Int(lessonToSync.serverId))
        NSLog("Current thread \(NSThread.currentThread())")
        NSLog("%@", NSThread.callStackSymbols())
        let networkManager = NetworkManager.sharedNetworkManager
        networkManager.getLessonWithID(lessonToSync.serverId, asPreviewOnly: false, onSuccess: {
            (retreivedLesson: Lesson) -> Void in
            NSLog("PULLING LESSON: %ld", Int(lessonToSync.serverId))
            NSLog("Current thread \(NSThread.currentThread())")
            NSLog("%@", NSThread.callStackSymbols())
            lessonToSync.setToLesson(retreivedLesson)
            var neededAudios = [Audio]()
            for wordAndAudio in lessonToSync.listOfMissingFiles() {
                let (_, audio) = wordAndAudio
                neededAudios.append(audio)
            }
            let lessonProgress = NSProgress(totalUnitCount: neededAudios.count + 1)
            lessonProgress.completedUnitCount = 1
            lessonToSync.remoteChangesSinceLastSync = neededAudios.count > 0
            progressBlock?(lesson: lessonToSync, progress: lessonProgress)
            NSLog("NEEDED AUDIOS: %@", neededAudios)
            for file: Audio in neededAudios {
                guard let serverId = file.serverId else {
                    // SHOULD NOT HAPPEN!!!
                    assert(false)
                    continue
                }
                NSLog("PULLING AUDIO: \(serverId)")
                NSLog("Current thread \(NSThread.currentThread())")
                let fileProgress = NSProgress(totalUnitCount: 1000)
                lessonProgress.addChild(fileProgress, withPendingUnitCount: 1)
                networkManager.pullAudio(file, withProgress: {
                    (fileProgressFloat: Float) -> Void in
                    fileProgress.completedUnitCount = Int64(1000*fileProgressFloat)
                    NSLog("FILE PROGRESS: \(serverId) \(fileProgress.localizedAdditionalDescription)")
                    NSLog("Current thread \(NSThread.currentThread())")
                    if fileProgressFloat == 1 {
                        if lessonProgress.fractionCompleted == 1 {
                            lessonToSync.remoteChangesSinceLastSync = false
                        }
                        progressBlock?(lesson: lessonToSync, progress: lessonProgress)
                    }
                    }, onFailure: nil)
            }
            }, onFailure: {
                (error: NSError) -> Void in
                failureBlock?(error: error)
        })
    }
    
    private func pushLessonWithFiles(lessonToSync: Lesson, withProgress progressBlock: ((lesson: Lesson, progress: NSProgress) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let networkManager = NetworkManager.sharedNetworkManager
        networkManager.postLesson(lessonToSync, onSuccess: {
            (newLessonID: Int, newServerVersion: Int, neededWordAndFileCodes: [NetworkManager.MissingFile]) -> Void in
            let lessonProgress = NSProgress(totalUnitCount: neededWordAndFileCodes.count + 1)
            lessonProgress.completedUnitCount = 1
            lessonToSync.serverId = newLessonID
            if neededWordAndFileCodes.count == 0 {
                lessonToSync.serverTimeOfLastCompletedSync = newServerVersion
                lessonToSync.localChangesSinceLastSync = false
            }
            progressBlock?(lesson: lessonToSync, progress: lessonProgress)
            for missingFile in neededWordAndFileCodes {
                let fileProgress = NSProgress(totalUnitCount: 1000)
                lessonProgress.addChild(fileProgress, withPendingUnitCount: 1)
                let word: Word = lessonToSync.wordWithCode(missingFile.wordUUID)!
                let file: Audio = word.fileWithCode(missingFile.audioUUID)!
                networkManager.putAudioFileAtPath(file.fileURL()!.absoluteString, forLesson: lessonToSync, withWord: word, usingCode: file.uuid, withProgress: {(fileProgressFloat: Float) -> Void in
                    fileProgress.completedUnitCount = Int64(1000 * fileProgressFloat)
                    if fileProgressFloat == 1 {
                        progressBlock?(lesson: lessonToSync, progress: lessonProgress)
                    }
                    }, onFailure: nil)
            }
            }, onFailure: {(error: NSError) -> Void in
                failureBlock?(error: error)
        })
    }
    
    static func getWordWithFiles(wordID: Int, withProgress progress: ((word: Word, progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let networkManager = NetworkManager.sharedNetworkManager
        networkManager.getWordWithID(wordID, onSuccess: {(word: Word) -> Void in
            let neededAudios = word.listOfMissingFiles()
            var wordProgress = Float(1.0)
            let totalWordProgress = Float(neededAudios.count) + 1
            progress?(word: word, progress: wordProgress / totalWordProgress)
            var progressPerAudioFile = [String : Float]()
            for file: Audio in neededAudios {
                progressPerAudioFile[file.uuid] = 0.0
                networkManager.pullAudio(file, withProgress: {(fileProgress: Float) -> Void in
                    NSLog("FILE PROGRESS: %@ %@", file.uuid, fileProgress)
                    progressPerAudioFile[file.uuid] = fileProgress
                    var filesProgress = Float(0)
                    for value: Float in progressPerAudioFile.values {
                        filesProgress += value
                    }
                    wordProgress = filesProgress + 1
                    progress?(word: word, progress: wordProgress / totalWordProgress)
                    }, onFailure: nil)
            }
            }, onFailure: {
                (error: NSError) -> Void in
                failureBlock?(error: error)
        })
    }
}
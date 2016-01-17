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
    lazy var lessonTransferProgress = [Lesson : Float]()
    
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
            guard let lessonJson: NSData = lesson.toJSON() else {
                continue;
            }
            if let lessonJsonSTRING = String(data: lessonJson, encoding: NSUTF8StringEncoding) {
                lessonJsons.append(lessonJsonSTRING)
            }
        }
        defaults.setObject(lessonJsons, forKey: "lessons-\(name)")
        defaults.synchronize()
    }
    
    func syncStaleLessonsWithProgress(progress: (lesson: Lesson, progress: Float) -> Void) {
        // Syncs the ones that are stale
        var staleLessons = [Lesson]()
        for lesson in self.lessons {
            if lesson.localChangesSinceLastSync || lesson.remoteChangesSinceLastSync {
                guard lessonTransferProgress[lesson] == nil else {
                    continue
                }
                staleLessons.append(lesson)
                self.lessonTransferProgress[lesson] = 0
                progress(lesson: lesson, progress: 0)
            }
        }
        self.syncLessons(staleLessons) {
            (syncLesson, syncProgress) -> Void in
            if syncProgress < 1.0 {
                self.lessonTransferProgress[syncLesson] = syncProgress
            } else {
                self.lessonTransferProgress.removeValueForKey(syncLesson)
                self.writeToDisk()
            }
            progress(lesson: syncLesson, progress: syncProgress)
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
    
    /// CONVENIENT HELPER FUNCTIONS
    
    private func syncLessons(lessons: [Lesson], withProgress progressBlock: ((lesson: Lesson, progress: Float) -> Void)?) {
        for lessonToSync: Lesson in lessons {
            // Which direction is this motherfucter syncing?
            if lessonToSync.localChangesSinceLastSync {
                self.pushLessonWithFiles(lessonToSync, withProgress: progressBlock, onFailure: nil)
            }
            else if lessonToSync.remoteChangesSinceLastSync || lessonToSync.listOfMissingFiles().count > 0 {
                self.pullLessonWithFiles(lessonToSync, withProgress: progressBlock, onFailure: nil)
            }
            else {
                NSLog("No which way for this lesson to sync: %@", lessonToSync)
                progressBlock?(lesson: lessonToSync, progress: 1)
            }
        }
    }
    
    private func pullLessonWithFiles(var lessonToSync: Lesson, withProgress progressBlock: ((lesson: Lesson, progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        NSLog("WANT TO PULL LESSON: %ld", Int(lessonToSync.serverId))
        NSLog("%@", NSThread.callStackSymbols())
        let networkManager = NetworkManager.sharedNetworkManager
        networkManager.getLessonWithID(lessonToSync.serverId, asPreviewOnly: false, onSuccess: {
            (retreivedLesson: Lesson) -> Void in
            NSLog("PULLING LESSON: %ld", Int(lessonToSync.serverId))
            NSLog("%@", NSThread.callStackSymbols())
            lessonToSync = retreivedLesson
            var neededAudios = [Audio]()
            for audioAndWord: [String : AnyObject] in lessonToSync.listOfMissingFiles() {
                neededAudios.append(audioAndWord["audio"] as! Audio)
            }
            var lessonProgress: Float = 1
            let totalLessonProgress: Float = Float(neededAudios.count) + 1
            lessonToSync.remoteChangesSinceLastSync = neededAudios.count > 0
            progressBlock?(lesson: lessonToSync, progress: lessonProgress / totalLessonProgress)
            var progressPerAudioFile = [String : Float]()
            NSLog("NEEDED AUDIOS: %@", neededAudios)
            for file: Audio in neededAudios {
                guard let serverId = file.serverId else {
                    continue
                }
                NSLog("PULLING AUDIO: %@", serverId)
                progressPerAudioFile[file.uuid] = 0.0
                networkManager.pullAudio(file, withProgress: {(fileProgress: Float) -> Void in
                    NSLog("FILE PROGRESS: %@ %@", serverId, fileProgress)
                    progressPerAudioFile[file.uuid] = fileProgress
                    var filesProgress = Float(0)
                    for value: Float in progressPerAudioFile.values {
                        filesProgress += value
                    }
                    lessonProgress = filesProgress + 1
                    if fileProgress == 1 {
                        if lessonProgress == totalLessonProgress {
                            lessonToSync.remoteChangesSinceLastSync = false
                        }
                        progressBlock?(lesson: lessonToSync, progress: lessonProgress / totalLessonProgress)
                    }
                    }, onFailure: nil)
            }
            }, onFailure: {
                (error: NSError) -> Void in
                failureBlock?(error: error)
        })
    }
    
    private func pushLessonWithFiles(lessonToSync: Lesson, withProgress progressBlock: ((lesson: Lesson, progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let networkManager = NetworkManager.sharedNetworkManager
        networkManager.postLesson(lessonToSync, onSuccess: {
            (newLessonID: Int, newServerVersion: Int, neededWordAndFileCodes: [NetworkManager.MissingFile]) -> Void in
            var lessonProgress: Float = 1
            let totalLessonProgress = Float(neededWordAndFileCodes.count) + 1
            lessonToSync.serverId = newLessonID
            if neededWordAndFileCodes.count == 0 {
                lessonToSync.serverTimeOfLastCompletedSync = newServerVersion
                lessonToSync.localChangesSinceLastSync = false
            }
            progressBlock?(lesson: lessonToSync, progress: lessonProgress / totalLessonProgress)
            for missingFile in neededWordAndFileCodes {
                let word: Word = lessonToSync.wordWithCode(missingFile.wordUUID)!
                let file: Audio = word.fileWithCode(missingFile.audioUUID)!
                networkManager.putAudioFileAtPath(file.fileURL()!.absoluteString, forLesson: lessonToSync, withWord: word, usingCode: file.uuid, withProgress: {(fileProgress: Float) -> Void in
                    if fileProgress == 1 {
                        lessonProgress = lessonProgress + 1
                        if lessonProgress == totalLessonProgress {
                            lessonToSync.serverTimeOfLastCompletedSync = newServerVersion
                            lessonToSync.localChangesSinceLastSync = false
                        }
                        progressBlock?(lesson: lessonToSync, progress: lessonProgress / totalLessonProgress)
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
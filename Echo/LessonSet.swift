//
//  LessonSet.swift
//  Echo
//
//  Created by William Entriken on 1/5/16.
//
//

import Foundation

class LessonSet: NSObject {
    var name: String
    var lessons = [Lesson]()
    private lazy var lessonTransferProgress = [Lesson : Float]()
    
    init(name: String) {
        self.name = name
        super.init();
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
        let networkManager = NetworkManager.sharedNetworkManager()
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
        networkManager.syncLessons(staleLessons) { (syncedLesson: Lesson!, syncedProgress: NSNumber!) -> Void in
            if syncedProgress.floatValue < 1.0 {
                self.lessonTransferProgress[syncedLesson] = Float(syncedProgress)
            } else {
                self.lessonTransferProgress.removeValueForKey(syncedLesson)
                self.writeToDisk()
            }
            progress(lesson: syncedLesson, progress: Float(syncedProgress))
        }
    }
    
    //TODO: instead just expose the dictionary directly
    func transferProgressForLesson(lesson: Lesson) -> Float {
        // nil or 0.0 to 1.0
        if let retval: Float = self.lessonTransferProgress[lesson] {
            return retval
        }
        return 0 //TODO: MAKE THIS OPTIONAL RETURN
    }
    
    func deleteLesson(lesson: Lesson) {
        lesson.deleteFromDisk()
        self.lessonTransferProgress.removeValueForKey(lesson)
        if let index = self.lessons.indexOf(lesson) {
            self.lessons.removeAtIndex(index)
        }
        self.writeToDisk()
    }
    
    //TODO: make this throw instead of failure block?
    func deleteLessonAndStopSharing(lesson: Lesson, onSuccess success: () -> Void, onFailure failure: (error: NSError) -> Void) {
        let networkManager: NetworkManager = NetworkManager.sharedNetworkManager()
        networkManager.deleteLessonWithID(lesson.lessonID, onSuccess: {() -> Void in
            self.deleteLesson(lesson)
            success()
        }, onFailure: {(theError: NSError!) -> Void in
            failure(error: theError)
        })
    }
    
    //TODO: this can be more swifty
    func addOrUpdateLesson(lesson: Lesson) {
        if self.lessons.contains(lesson) {
            self.writeToDisk()
            return
        } else if lesson.lessonID > 0 {
            for var i = 0; i < (self.lessons).count; i++ {
                if self.lessons[i].lessonID == lesson.lessonID {
                    self.lessons[i] = lesson
                    self.writeToDisk()
                    return
                }
            }
        }
        self.lessons.append(lesson)
        self.writeToDisk()
    }
    
    //TODO: make this a single lesson function?
    func setRemoteUpdatesForLessonsWithIDs(newLessonIDs: [NSNumber]) {
        for lesson in self.lessons {
            if newLessonIDs.contains(lesson.lessonID) {
                lesson.remoteChangesSinceLastSync = true
            }
        }
        self.writeToDisk()
    }
}
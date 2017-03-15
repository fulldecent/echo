//
//  LessonSet.swift
//  Echo
//
//  Created by Full Decent on 1/15/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import Foundation

protocol LessonLibraryDelegate: class {
    func lessonLibrary(library: LessonLibrary, downloadedLessonWithIndex index: Int)
}

/// Stores all your local lessons
class LessonLibrary {
    enum LessonStatus {
        case usable
        case notUsable // 1+ words are missing
        case downloading(progress: Progress)
    }
    
    var lessonsAndStatus: [(lesson: Lesson, status: LessonStatus)]
    weak var delegate: LessonLibraryDelegate? = nil
    private static let userDefaultsKey = "myLessons"
    
    private init() {
        lessonsAndStatus = []
    }
    
    static var main: LessonLibrary = {
        let retval = LessonLibrary()
        let defaults = UserDefaults.standard
        if let jsons = defaults.object(forKey: userDefaultsKey) as? [[String: Any]] {
            for lessonJson in jsons {
                guard let lesson = Lesson(json: lessonJson) else {
                    continue
                }
                retval.append(lesson: lesson)
            }
        }
        return retval
    }()
    
    func append(lesson: Lesson) {
        if lesson.missingFiles().count > 0 {
            let progress = lesson.fetchFiles {_ in
                if let index = self.lessonsAndStatus.index(where: {$0.lesson.id == lesson.id}) {
                    self.lessonsAndStatus[index].status = .usable
                    self.delegate?.lessonLibrary(library: self, downloadedLessonWithIndex: index)
                }
            }
            lessonsAndStatus.append((lesson: lesson, status: .downloading(progress: progress)))
        } else {
            lessonsAndStatus.append((lesson: lesson, status: .usable))
        }
        writeToDisk()
    }
    
    private func writeToDisk() {
        let defaults = UserDefaults.standard
        let lessonsJSON = lessonsAndStatus.map {$0.lesson.toJSON()}
        defaults.set(lessonsJSON, forKey: LessonLibrary.userDefaultsKey)
        defaults.synchronize()
    }
}

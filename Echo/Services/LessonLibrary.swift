//
//  LessonLibrary.swift
//  Echo
//
//  Created by Full Decent on 1/15/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import Foundation
import Combine

/// A wrapper to make any Error `Identifiable`, suitable for use with SwiftUI's `.alert(item:)` modifier.
struct AppError: Identifiable {
    let id = UUID()
    let underlyingError: Error

    var localizedDescription: String {
        underlyingError.localizedDescription
    }
}

@MainActor
final class LessonLibrary: ObservableObject {
    static let shared = LessonLibrary()
    
    @Published var lessonsWithStatus: [(lesson: Lesson, status: Status)]
    @Published var lastError: AppError?
    
    private let api: EchoAPIProtocol
    private static let userDefaultsKey = "localLessons"

    private init(api: EchoAPIProtocol = EchoAPI.shared) {
        self.lessonsWithStatus = Self.loadFromUserDefaults().map { (lesson: $0, status: .available) }
        self.api = api
    }
    
    enum Status: Equatable {
        case available
        case downloading(progress: Double)
    }
    
    // MARK: - Public API
    
    func downloadLesson(id: Int) {
        Task {
            if lessonsWithStatus.contains(where: { $0.lesson.id == id && $0.status == .available }) {
                return
            }

            actor Counter {
                var value = 0
                func increment() { value += 1 }
            }
            
            var placeholderIndex: Int?

            do {
                let placeholder = (
                    lesson: Lesson(id: id, language: .en, name: "Loading...", username: "", userId: 0, likes: 0, words: []),
                    status: Status.downloading(progress: 0.0)
                )

                if let existingIndex = self.lessonsWithStatus.firstIndex(where: { $0.lesson.id == id }) {
                    self.lessonsWithStatus[existingIndex] = placeholder
                    placeholderIndex = existingIndex
                } else {
                    self.lessonsWithStatus.append(placeholder)
                    placeholderIndex = self.lessonsWithStatus.count - 1
                }
                
                guard let strongPlaceholderIndex = placeholderIndex else { return }

                let lesson = try await api.getLessonMetadata(id: id)
                self.lessonsWithStatus[strongPlaceholderIndex].lesson = lesson
                
                let counter = Counter()
                let audioCount = lesson.words.reduce(0) { $0 + $1.audios.count }
                let totalItems = 1 + audioCount

                let reportProgress: @Sendable (Double) -> Void = { progress in
                    Task { @MainActor in
                        if self.lessonsWithStatus.indices.contains(strongPlaceholderIndex),
                           self.lessonsWithStatus[strongPlaceholderIndex].lesson.id == id {
                            self.lessonsWithStatus[strongPlaceholderIndex].status = .downloading(progress: progress)
                        }
                    }
                }
                
                // Separately handle avatar download so it doesn't fail the whole process
                do {
                    let avatarData = try await api.getUserAvatarFile(id: lesson.userId)
                    try avatarData.write(to: lesson.userAvatarLocalURL(), options: .atomic)
                } catch {
                    print("Avatar download failed for lesson \(id): \(error). Proceeding without it.")
                }
                await counter.increment() // Increment counter regardless of avatar success
                
                let currentProgress = Double(await counter.value) / Double(totalItems)
                reportProgress(currentProgress)
                
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for word in lesson.words {
                        for audio in word.audios {
                            group.addTask {
                                let audioData = try await self.api.getAudio(id: audio.id)
                                try audioData.write(to: audio.localURL(), options: .atomic)
                            }
                        }
                    }
                    
                    for try await _ in group {
                        await counter.increment()
                        let progress = Double(await counter.value) / Double(totalItems)
                        reportProgress(progress)
                    }
                }
            
                if self.lessonsWithStatus.indices.contains(strongPlaceholderIndex),
                   self.lessonsWithStatus[strongPlaceholderIndex].lesson.id == id {
                    self.lessonsWithStatus[strongPlaceholderIndex].status = .available
                    self.saveToUserDefaults()
                }

            } catch {
                if let idx = self.lessonsWithStatus.firstIndex(where: { $0.lesson.id == id }) {
                    self.lessonsWithStatus.remove(at: idx)
                }
                self.lastError = AppError(underlyingError: error)
            }
        }
    }
    
    func deleteLesson(id: Int) {
        guard let index = lessonsWithStatus.firstIndex(where: { $0.lesson.id == id }) else { return }
        let lesson = lessonsWithStatus[index].lesson
        lessonsWithStatus.remove(at: index)
        
        Task.detached(priority: .background) {
            let fileManager = FileManager.default
            for word in lesson.words {
                for audio in word.audios {
                    try? fileManager.removeItem(at: audio.localURL())
                }
            }
            try? fileManager.removeItem(at: lesson.userAvatarLocalURL())
        }
        
        saveToUserDefaults()
    }

    func cleanOrphans() {
        var knownURLs = Set<URL>()
        for entry in lessonsWithStatus where entry.status == .available {
            let lesson = entry.lesson
            knownURLs.insert(lesson.userAvatarLocalURL())
            for word in lesson.words {
                for audio in word.audios {
                    knownURLs.insert(audio.localURL())
                }
            }
        }
        
        Task.detached(priority: .background) { [knownURLs] in
            let fileManager = FileManager.default
            guard let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last else { return }
            
            guard let allFiles = try? fileManager.contentsOfDirectory(at: docsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else { return }
            
            for fileURL in allFiles where !knownURLs.contains(fileURL) {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }

    private static func loadFromUserDefaults() -> [Lesson] {
        guard let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey) else { return [] }
        do {
            return try JSONDecoder().decode([Lesson].self, from: data)
        } catch {
            print("Failed to decode lessons: \(error)")
            return []
        }
    }
    
    private func saveToUserDefaults() {
        do {
            let availableLessons = lessonsWithStatus
                .filter { $0.status == .available }
                .map { $0.lesson }
            let data = try JSONEncoder().encode(availableLessons)
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        } catch {
            print("Failed to encode lessons: \(error)")
        }
    }
}

// ViewModels.swift

import Foundation
import Combine

// Used by LessonPage
@MainActor
class LessonPageModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let lesson: Lesson
    
    @Published var name: String
    @Published var imageURL: URL
    @Published var words: [Word]
    @Published var isShuffle: Bool = false
    
    // DERIVED
    @Published var progressFraction: Double = 0.0
    @Published var progressText: String = ""

    init(lesson: Lesson) {
        self.lesson = lesson
        self.name = lesson.name
        self.imageURL = lesson.userAvatarLocalURL()
    self.words = lesson.words
        
        // This is a key part: when the `words` array is modified (e.g., a word is marked complete),
        // we recalculate our progress properties.
        $words
            .sink { [weak self] updatedWords in
                self?.updateProgress(from: updatedWords)
            }
            .store(in: &cancellables)
        
        // Initial calculation
        updateProgress(from: self.words)
    }

    private func updateProgress(from words: [Word]) {
        guard !words.isEmpty else {
            self.progressFraction = 0
            self.progressText = "0 / 0"
            return
        }
        
        let completedCount = words.filter(\.complete).count
        self.progressFraction = Double(completedCount) / Double(words.count)
        self.progressText = "\(completedCount) / \(words.count)"
    }
}

// SearchPageView.swift

import SwiftUI
import Combine

struct SearchPageView: View {
    @EnvironmentObject var lessonLibrary: LessonLibrary
    @StateObject private var searchViewModel = SearchViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    let onLessonSelected: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Patterned background
                EchoPatternBackground()
                
                VStack {
                Picker("Language", selection: $searchViewModel.selectedLanguage) {
                    ForEach(Language.allCases, id: \.self) { lang in
                        Text(lang.nativeName()).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                switch searchViewModel.state {
                case .idle:
                    Spacer()
                case .loading:
                    Spacer()
                    ProgressView()
                        .tint(.yellow)
                        .scaleEffect(1.5)
                    Spacer()
                case .failure(let error):
                    ContentUnavailableView(error.localizedDescription, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                case .success(let lessons):
                    if lessons.isEmpty {
                        ContentUnavailableView("No Lessons Found", systemImage: "magnifyingglass")
                    } else {
                        List(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                            SearchLessonRow(
                                lesson: lesson,
                                lessonLibrary: lessonLibrary,
                                index: index,
                                onDownload: {
                                    lessonLibrary.downloadLesson(id: lesson.id)
                                    onLessonSelected()
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                }
            }
            }
            .frame(minWidth: 400, minHeight: 400)
            .navigationTitle("Find Lessons")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task(id: searchViewModel.selectedLanguage) {
                // Perform search when language changes
                await searchViewModel.performSearch()
            }
        }
    }
    
    @MainActor
    class SearchViewModel: ObservableObject {
        enum State {
            case idle
            case loading
            case success([Lesson])
            case failure(Error)
        }
        
        @Published var selectedLanguage: Language = .en
        @Published private(set) var state: State = .idle
        
        let api: EchoAPIProtocol = EchoAPI.shared
        
        // Separate search task to prevent concurrent searches
        private var searchTask: Task<Void, Never>?
        
        func performSearch() async {
            // Cancel any in-flight search
            searchTask?.cancel()
            
            // Small debounce delay
            try? await Task.sleep(for: .milliseconds(300))
            
            // Check if cancelled during debounce
            if Task.isCancelled { return }
            
            state = .loading
            
            do {
                let lessons = try await api.searchLessonPreviews(language: selectedLanguage)
                
                // Check cancellation before updating state
                if !Task.isCancelled {
                    state = .success(lessons)
                }
            } catch {
                if !Task.isCancelled {
                    state = .failure(error)
                }
            }
        }
    }
    
    
    // MARK: - Search Lesson Row
    
    private struct SearchLessonRow: View {
        let lesson: Lesson
        let lessonLibrary: LessonLibrary
        let index: Int
        let onDownload: () -> Void
        @Environment(\.colorScheme) var colorScheme
        
        private var status: LessonLibrary.Status? {
            lessonLibrary.lessonsWithStatus.first(where: { $0.lesson.id == lesson.id })?.status
        }
        
        var body: some View {
            Button(action: {
                // Only allow download if not already downloaded or downloading
                if status == nil {
                    onDownload()
                }
            }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lesson.name)
                            .foregroundColor(.primary)
                            .font(.body)
                            .fontWeight(.medium)
                        Text("by \(lesson.username)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    // Status indicator
                    Group {
                        if let status = status {
                            switch status {
                            case .available:
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            case .downloading(let progress):
                                ProgressView(value: progress)
                                    .tint(.yellow)
                                    .frame(width: 30)
                            }
                        } else {
                            Image(systemName: "icloud.and.arrow.down")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.lessonGradient(index: index, colorScheme: colorScheme))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .contentShape(Rectangle()) // Makes the entire row tappable
            }
            .buttonStyle(.plain)
        }
    }
    
    private struct DownloadButton: View {
        @EnvironmentObject var lessonLibrary: LessonLibrary
        let lesson: Lesson
        let onDownloadStarted: () -> Void
        
        private var status: LessonLibrary.Status? {
            lessonLibrary.lessonsWithStatus.first(where: { $0.lesson.id == lesson.id })?.status
        }
        
        var body: some View {
            if let status = status {
                switch status {
                case .available:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.echoSuccess)
                case .downloading(let progress):
                    ProgressView(value: progress)
                        .tint(.echoAccent)
                        .frame(width: 30)
                }
            } else {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.title2)
                    .foregroundColor(.echoAccent)
            }
        }
    }
}

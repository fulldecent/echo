// MainView.swift

import SwiftUI

struct MainView: View {
    @EnvironmentObject var lessonLibrary: LessonLibrary
    @State private var showingSearch = false
    @State private var navigationPath = NavigationPath()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Patterned background
                EchoPatternBackground()
                
                List {
                    ForEach(Array(lessonLibrary.lessonsWithStatus.enumerated()), id: \.element.lesson.id) { index, entry in
                        NavigationLink(value: entry.lesson) {
                            LessonRow(lesson: entry.lesson, status: entry.status, index: index)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: deleteLesson)
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Echo")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingSearch = true }) {
                        Label("Add Lesson", systemImage: "plus")
                    }
                }
            }
            .overlay {
                if lessonLibrary.lessonsWithStatus.isEmpty {
                    ContentUnavailableView(
                        "No lessons",
                        systemImage: "book.closed",
                        description: Text("Tap the + button to find lessons")
                    )
                }
            }
            .navigationDestination(for: Lesson.self) { lesson in
                LessonPage(lesson: LessonPageModel(lesson: lesson))
            }
            .alert(item: $lessonLibrary.lastError) { appError in
                Alert(
                    title: Text("Error"),
                    message: Text(appError.localizedDescription),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingSearch) {
                SearchPageView(onLessonSelected: {
                    showingSearch = false
                })
            }
            }
        }
    }
    
    private func deleteLesson(at offsets: IndexSet) {
        for index in offsets {
            let entry = lessonLibrary.lessonsWithStatus[index]
            lessonLibrary.deleteLesson(id: entry.lesson.id)
        }
    }
}

// Reusable row view for displaying a lesson entry
private struct LessonRow: View {
    let lesson: Lesson
    let status: LessonLibrary.Status
    let index: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("by \(lesson.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            switch status {
            case .available:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            case .downloading(let progress):
                ProgressView(value: progress)
                    .tint(.yellow)
                    .frame(width: 50)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.lessonGradient(index: index, colorScheme: colorScheme))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

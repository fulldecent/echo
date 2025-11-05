//
//  LessonPage.swift
//  Echo
//
//  Created by Assistant on 2025-10-29.
//

import SwiftUI

struct LessonPage: View {
    @ObservedObject var lesson: LessonPageModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Patterned background
            EchoPatternBackground()
            
            List {
            // Header: image + progress (justified around)
            Section {
                HStack(spacing: 16) {
                    Spacer()
                    // Conditionally show avatar only if it exists
                    if FileManager.default.fileExists(atPath: lesson.imageURL.path) {
                        ImageFromURL(url: lesson.imageURL)
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Spacer()
                    }
                    PieProgressView(
                        fraction: lesson.progressFraction,
                        lineWidth: 10,
                        baseColor: Color.gray.opacity(0.3),
                        fillColor: .yellow
                    )
                    .frame(width: 60, height: 60)
                    Spacer()
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.95))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 16)
            )
            .listRowSeparator(.hidden)

            // Words list (first row is Shuffle)
            Section {
                NavigationLink(destination:
                                PracticeFlowContainer(
                                    lesson: lesson,
                                    currentIndex: lesson.words.isEmpty ? 0 : Int.random(in: 0..<lesson.words.count)
                                )
                                .onAppear { lesson.isShuffle = true }
                ) {
                    HStack {
                        Label("Shuffle", systemImage: "shuffle")
                            .foregroundColor(.primary)
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: colorScheme == .dark ? 
                                [Color(red: 0.5, green: 0.45, blue: 0.1), Color(red: 0.35, green: 0.3, blue: 0.07)] :
                                [Color.yellow.opacity(0.8), Color(red: 0.55, green: 0.50, blue: 0.16).opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 16)
                )
                .listRowSeparator(.hidden)

                ForEach(Array(lesson.words.enumerated()), id: \.offset) { pair in
                    let idx = pair.offset
                    let item = pair.element
                    NavigationLink(destination: PracticeFlowContainer(lesson: lesson, currentIndex: idx).onAppear { lesson.isShuffle = false }) {
                        HStack {
                            Text(item.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if item.complete {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wordGradient(index: idx, colorScheme: colorScheme))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .padding(.horizontal, 16)
                    )
                    .listRowSeparator(.hidden)
                }
            }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(lesson.name)
        }
    }
}

// MARK: - Practice container

private struct PracticeFlowContainer: View {
    @ObservedObject var lesson: LessonPageModel
    @State var currentIndex: Int
    @State private var handsFreeEnabled = false
    
    var body: some View {
        WordPracticePage(
            word: Binding(
                get: { lesson.words[currentIndex] },
                set: { lesson.words[currentIndex] = $0 }
            ),
            referenceImageURL: lesson.imageURL,
            startInHandsFree: handsFreeEnabled,
            onHandsFreeModeChange: { handsFreeEnabled = $0 },
            onNextWord: advance
        )
        .id(currentIndex)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        ))
        .animation(.easeInOut(duration: 0.3), value: currentIndex)
        .navigationTitle(lesson.words[currentIndex].name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func advance() {
        if lesson.words.isEmpty { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if lesson.isShuffle {
                var next = Int.random(in: 0..<lesson.words.count)
                if lesson.words.count > 1 {
                    while next == currentIndex { next = Int.random(in: 0..<lesson.words.count) }
                }
                currentIndex = next
            } else {
                currentIndex = (currentIndex + 1) % lesson.words.count
            }
        }
    }
}

// MARK: - Helpers

private struct ImageFromURL: View {
    let url: URL
    var body: some View {
        #if os(iOS)
        if let img = UIImage(contentsOfFile: url.path) {
            Image(uiImage: img).resizable()
        } else {
            Image(systemName: "photo").resizable()
        }
        #elseif os(macOS)
        if let img = NSImage(contentsOf: url) {
            Image(nsImage: img).resizable()
        } else {
            Image(systemName: "photo").resizable()
        }
        #endif
    }
}

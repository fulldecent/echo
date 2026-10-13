// EchoApp.swift

import SwiftUI

@main
struct EchoApp: SwiftUI.App {
  init() {
    #if os(macOS)
      MacScreenshot.exportIfRequested()
    #endif
  }

  // Use the shared LessonLibrary instance, which correctly uses EchoAPI.shared by default.
  @StateObject private var lessonLibrary = LessonLibrary.shared

  var body: some Scene {
    WindowGroup {
      MainView()
        .environmentObject(lessonLibrary)
        .screenshotLocale()
    }
  }
}

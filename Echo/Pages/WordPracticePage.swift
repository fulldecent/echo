import SwiftUI
import AVFoundation
import AVFAudio
import Combine
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct WordPracticePage: View {
    @Binding var word: Word
    let referenceImageURL: URL
    let startInHandsFree: Bool
    let onHandsFreeModeChange: (Bool) -> Void
    let onNextWord: () -> Void
    @StateObject private var audio = WordPracticeAudioManager()
    @Environment(\.colorScheme) var colorScheme
    @State private var isHandsFreeEnabled = false
    @State private var hfStepIndex: Int? = nil
    @State private var hfWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark ?
                    [Color(red: 0.12, green: 0.11, blue: 0.08), Color(red: 0.55, green: 0.50, blue: 0.16).opacity(0.2)] :
                    [Color(red: 0.95, green: 0.92, blue: 0.85), Color.yellow.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { geometry in
                let isWide = geometry.size.width >= 1.5 * geometry.size.height  // Threshold for horizontal vs vertical
                let sectionSize = min(geometry.size.width * 0.3, min(geometry.size.height * 0.4, 300))  // Proportional, capped
                let controlSize = min(sectionSize * 1.1, 150)  // Slightly larger than image for prominence
                let iconScale = min(1.0, geometry.size.width / 400)  // Scale down icons on very small screens

                VStack(spacing: 12) {  // Reduced overall spacing for compactness
                    if isWide {
                        HStack(spacing: 16) {
                            userSection(geometry: geometry, sectionSize: sectionSize, controlSize: controlSize, iconScale: iconScale)
                            referenceSection(geometry: geometry, sectionSize: sectionSize, controlSize: controlSize, iconScale: iconScale)
                        }
                    } else {
                        VStack(spacing: 12) {
                            userSection(geometry: geometry, sectionSize: sectionSize, controlSize: controlSize, iconScale: iconScale)
                            referenceSection(geometry: geometry, sectionSize: sectionSize, controlSize: controlSize, iconScale: iconScale)
                        }
                    }

                    if audio.isPlaying {
                        WaveformView(progress: audio.playbackProgress)
                            .frame(height: min(geometry.size.height * 0.1, 50))
                    }

                    Spacer()

                    Group {
                        if isHandsFreeEnabled {
                            handsFreeKebabView(iconScale: iconScale)
                        } else {
                            HStack(spacing: 12) {
                                Button { audio.resetRecording() } label: {
                                    Image(systemName: "arrow.counterclockwise")
                                        .resizable()
                                        .frame(width: 26 * iconScale, height: 26 * iconScale)
                                        .foregroundColor(colorScheme == .dark ? .secondary : Color(red: 0.55, green: 0.50, blue: 0.16))
                                }
                                Spacer()
                                Toggle("", isOn: $word.complete)
                                    .labelsHidden()
                                    .tint(.green)
                                Spacer()
                                Button(action: { enterHandsFree() }) {
                                    handsFreeGridIcon(scale: iconScale)
                                }
                                Spacer()
                                Button(action: { onNextWord() }) {
                                    Image(systemName: "forward.fill")
                                        .resizable()
                                        .frame(width: 30 * iconScale, height: 30 * iconScale)
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .scaleEffect(iconScale)  // Compress controls on tiny windows
                }
                .padding(8)  // Minimal padding to fit small screens
            }
            .navigationTitle(word.name)
            .onAppear {
                audio.requestPermission()
                if startInHandsFree && !isHandsFreeEnabled {
                    enterHandsFree(auto: true)
                }
            }
            .onDisappear {
                audio.cancelAll()
                cancelHandsFree()
            }
            .onChange(of: word.id) { _, _ in
                if startInHandsFree {
                    enterHandsFree(auto: true)
                }
            }
            .onReceive(audio.$state) { newState in
                guard isHandsFreeEnabled else { return }
                handleAudioStateChange(newState)
            }
        }
        .frame(minWidth: 200, minHeight: 200)  // macOS minimum
    }

    // Extracted user section with grouping
    private func userSection(geometry: GeometryProxy, sectionSize: CGFloat, controlSize: CGFloat, iconScale: CGFloat) -> some View {
        VStack(spacing: 4) {  // Tighter spacing for association
            let userImg = imageFromBundle(filename: "User.jpg")
            userImg
                .resizable()
                .scaledToFit()
                .frame(maxWidth: sectionSize)
                .clipped()

            ZStack {
                Circle()
                    .fill(audio.isRecording ? Color.red : Color.yellow)
                    .frame(width: controlSize, height: controlSize)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                Image(systemName: audio.userRecordingURL == nil ? "mic.fill" : "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: controlSize * 0.5)
                    .foregroundColor(colorScheme == .dark ? Color.primary : .white)
                if audio.isRecording {
                    Text("Recording...")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? Color.primary : .white)
                        .offset(y: controlSize * 0.375)
                }
            }
            .onTapGesture {
                if audio.userRecordingURL != nil, !audio.isRecording {
                    audio.playUser()
                } else if !audio.isRecording && !audio.isPlaying {
                    audio.beginRecordingFlow()
                }
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))  // Subtle grouping background
    }

    // Extracted reference section with grouping
    private func referenceSection(geometry: GeometryProxy, sectionSize: CGFloat, controlSize: CGFloat, iconScale: CGFloat) -> some View {
        VStack(spacing: 4) {  // Tighter spacing
            imageFromURL(referenceImageURL)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: sectionSize)
                .clipped()

            Button(action: {
                let url = word.audios.first?.localURL() ?? URL(fileURLWithPath: "/dev/null")
                audio.playReference(url: url)
            }) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: controlSize, height: controlSize)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .overlay(
                        Image(systemName: "play.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: controlSize * 0.5)
                            .foregroundColor(.white)
                    )
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
    }

    // Updated handsFreeKebabView with scaling
    @ViewBuilder
    private func handsFreeKebabView(iconScale: CGFloat) -> some View {
        HStack(spacing: 12) {
            Button(action: { cancelHandsFree() }) {
                Image(systemName: "xmark.circle")
                    .resizable().frame(width: 26 * iconScale, height: 26 * iconScale)
                    .foregroundColor(.red)
            }
            Spacer()
            HStack(spacing: 8) {
                ForEach(hfSteps.indices, id: \.self) { idx in
                    let step = hfSteps[idx]
                    let isActive = hfStepIndex == idx
                    icon(for: step)
                        .foregroundColor(isActive ? .yellow : .secondary)
                        .scaleEffect(isActive ? 1.2 * iconScale : iconScale)
                        .animation(.easeInOut(duration: 0.2), value: isActive)
                }
            }
        }
        .padding(.horizontal, 8)
        .transition(.opacity.combined(with: .scale))
    }

    // Updated handsFreeGridIcon with scaling
    private func handsFreeGridIcon(scale: CGFloat) -> some View {
        VStack(spacing: 2 * scale) {
            HStack(spacing: 2 * scale) {
                Image(systemName: "play.fill").frame(width: 10 * scale, height: 10 * scale)
                Image(systemName: "record.circle").frame(width: 10 * scale, height: 10 * scale)
                Image(systemName: "play.fill").frame(width: 10 * scale, height: 10 * scale)
            }
            HStack(spacing: 2 * scale) {
                Image(systemName: "play.fill").frame(width: 10 * scale, height: 10 * scale)
                Image(systemName: "play.fill").frame(width: 10 * scale, height: 10 * scale)
                Image(systemName: "forward.fill").frame(width: 10 * scale, height: 10 * scale)
            }
        }
        .foregroundColor(.yellow)
        .frame(width: 34 * scale, height: 34 * scale)
    }
}
    
// MARK: - Waveform

private struct WaveformView: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midHeight = height / 2
                let wavelength = max(width / 10, 1)
                let progressWidth = width * progress
                
                var isFirst = true
                var x: CGFloat = 0
                while x < progressWidth {
                    let normalizedX = x / wavelength
                    let y = midHeight + sin(normalizedX * .pi * 2) * (height / 4)
                    if isFirst {
                        path.move(to: CGPoint(x: x, y: y))
                        isFirst = false
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    x += 1
                }
            }
            .stroke(Color.yellow, lineWidth: 3)
        }
    }
}

// MARK: - Preview

struct WordPracticePage_Previews: PreviewProvider {
    static var previews: some View {
        // In preview only: generate a short tone at the same path that Audio.localURL() would use
        let previewAudio = Audio(id: 999)
        let refURL = previewAudio.localURL()
        if !FileManager.default.fileExists(atPath: refURL.path) {
            let sampleRate: Double = 44100
            let duration: Double = 1.0
            let frequency: Double = 440.0
            let amplitude: Float = 0.5
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            let frames = Int(sampleRate * duration)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))!
            buffer.frameLength = buffer.frameCapacity
            let floats = buffer.floatChannelData!.pointee
            for i in 0..<frames { floats[i] = sin(2 * .pi * frequency * Double(i) / sampleRate).float * amplitude }
            do {
                // Ensure directory exists
                try FileManager.default.createDirectory(at: refURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                let file = try AVAudioFile(forWriting: refURL, settings: format.settings, commonFormat: .pcmFormatFloat32, interleaved: false)
                try file.write(from: buffer)
            } catch {
                print("Preview tone write error:", error)
            }
        }
        let previewWord = Word(id: 1, name: "ladder", audios: [previewAudio], complete: false)
        
        return NavigationStack {
            WordPracticePage(
                word: .constant(previewWord),
                referenceImageURL: Bundle.main.url(forResource: "User", withExtension: "jpg") ?? URL(fileURLWithPath: "/dev/null"),
                startInHandsFree: false,
                onHandsFreeModeChange: { _ in },
                onNextWord: {}
            )
        }
    }
}

private extension Double {
    var float: Float { Float(self) }
}

// MARK: - Image loading helpers

private extension WordPracticePage {
    func imageFromURL(_ url: URL) -> Image {
        #if os(iOS)
        if let img = UIImage(contentsOfFile: url.path) { return Image(uiImage: img) }
        #elseif os(macOS)
        if let img = NSImage(contentsOf: url) { return Image(nsImage: img) }
        #endif
        return Image(systemName: "photo")
    }
    
    func imageFromBundle(filename: String) -> Image {
        let ns = filename as NSString
        let name = ns.deletingPathExtension
        let ext = ns.pathExtension.isEmpty ? nil : ns.pathExtension
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return imageFromURL(url)
        }
        return Image(systemName: "person.crop.circle")
    }
}

// MARK: - Hands-free UI and logic

private extension WordPracticePage {
    // Hands-free step order: play reference first so user hears target, then record
    enum HFStep: Int, CaseIterable { case ref1 = 0, record, user1, ref2, user2, advance }
    var hfSteps: [HFStep] { [.ref1, .record, .user1, .ref2, .user2, .advance] }

    func handsFreeGridIcon() -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                // First item: play, Second: record
                Image(systemName: "play.fill")
                Image(systemName: "record.circle")
                Image(systemName: "play.fill")
            }
            HStack(spacing: 2) {
                Image(systemName: "play.fill")
                Image(systemName: "play.fill")
                Image(systemName: "forward.fill")
            }
        }
        .foregroundColor(.yellow)
        .frame(width: 34, height: 34)
        .accessibilityLabel("Hands-free mode")
    }

    @ViewBuilder
    func handsFreeKebabView() -> some View {
        HStack(spacing: 16) {
            // Brake / exit
            Button(action: { cancelHandsFree() }) {
                Image(systemName: "xmark.circle")
                    .resizable().frame(width: 26, height: 26)
                    .foregroundColor(.red)
                    .accessibilityLabel("Exit hands-free")
            }
            Spacer()
            // Kebab: sequence of six icons with simple highlight/animation
            HStack(spacing: 10) {
                ForEach(hfSteps.indices, id: \.self) { idx in
                    let step = hfSteps[idx]
                    let isActive = hfStepIndex == idx
                    icon(for: step)
                        .foregroundColor(isActive ? .yellow : .secondary)
                        .scaleEffect(isActive ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isActive)
                }
            }
        }
        .padding(.horizontal)
        .transition(.opacity.combined(with: .scale))
    }

    func icon(for step: HFStep) -> Image {
        switch step {
        case .record: return Image(systemName: "record.circle")
        case .ref1, .ref2: return Image(systemName: "play.fill")
        case .user1, .user2: return Image(systemName: "play.fill")
        case .advance: return Image(systemName: "forward.fill")
        }
    }

    func enterHandsFree(auto: Bool = false) {
        withAnimation { isHandsFreeEnabled = true }
        onHandsFreeModeChange(true)
        // Reset any existing recording to a virgin state
        audio.resetRecording()
        // Brief reveal delay before starting
        scheduleHFStart(after: 0.25)
    }

    func cancelHandsFree() {
        hfWorkItem?.cancel(); hfWorkItem = nil
        withAnimation { isHandsFreeEnabled = false }
        hfStepIndex = nil
        onHandsFreeModeChange(false)
    }

    func scheduleHFStart(after delay: TimeInterval) {
        let work = DispatchWorkItem { startHFSequence() }
        hfWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func startHFSequence() {
        runStep(.ref1)
    }

    func runStep(_ step: HFStep) {
        guard isHandsFreeEnabled else { return }
        hfStepIndex = step.rawValue
        switch step {
        case .ref1:
            let url = word.audios.first?.localURL() ?? URL(fileURLWithPath: "/dev/null")
            audio.playReference(url: url)
        case .record:
            // Start recording via the same flow as the user button
            audio.beginRecordingFlow()
        case .user1:
            audio.playUser()
        case .ref2:
            let url = word.audios.first?.localURL() ?? URL(fileURLWithPath: "/dev/null")
            audio.playReference(url: url)
        case .user2:
            audio.playUser()
        case .advance:
            // After small delay, advance to next word and continue hands-free
            let work = DispatchWorkItem {
                onNextWord()
            }
            hfWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
        }
    }

    func handleAudioStateChange(_ state: WordPracticeAudioManager.State) {
        guard isHandsFreeEnabled else { return }
        switch state {
        case .promptingStopFailure:
            // Treat as brake; exit hands-free on failure
            cancelHandsFree()
        case .idle:
            // Transition once actions complete
            guard let idx = hfStepIndex, let step = HFStep(rawValue: idx) else { return }
            switch step {
            case .ref1:
                // After hearing reference, move to recording with a slight delay
                let work = DispatchWorkItem { runStep(.record) }
                hfWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
            case .record:
                // Recording finished, ensure file is ready before playing user
                if audio.userRecordingURL != nil {
                    let work = DispatchWorkItem { runStep(.user1) }
                    hfWorkItem = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
                } else {
                    // If not ready, try a short retry once
                    let work = DispatchWorkItem { if audio.userRecordingURL != nil { runStep(.user1) } else { cancelHandsFree() } }
                    hfWorkItem = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
                }
            case .user1:
                let work = DispatchWorkItem { runStep(.ref2) }
                hfWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
            case .ref2:
                let work = DispatchWorkItem { runStep(.user2) }
                hfWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
            case .user2:
                let work = DispatchWorkItem { runStep(.advance) }
                hfWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
            case .advance:
                break
            }
        default:
            break
        }
    }
}

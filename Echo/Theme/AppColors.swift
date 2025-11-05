//
//  AppColors.swift
//  Echo
//
//  Created by Assistant on 2025-11-03.
//

import SwiftUI

extension Color {
    // MARK: - Gradient Helpers
    
    /// Returns a vibrant gradient for lesson cards based on index
    static func lessonGradient(index: Int, colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            // Dark mode: darker, more saturated backgrounds for white text
            let gradients: [LinearGradient] = [
                LinearGradient(colors: [Color(red: 0.5, green: 0.45, blue: 0.1), Color(red: 0.4, green: 0.35, blue: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing),
                LinearGradient(colors: [Color(red: 0.15, green: 0.35, blue: 0.5), Color(red: 0.1, green: 0.25, blue: 0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                LinearGradient(colors: [Color(red: 0.5, green: 0.2, blue: 0.15), Color(red: 0.4, green: 0.15, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                LinearGradient(colors: [Color(red: 0.2, green: 0.4, blue: 0.15), Color(red: 0.15, green: 0.3, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                LinearGradient(colors: [Color(red: 0.4, green: 0.15, blue: 0.45), Color(red: 0.3, green: 0.1, blue: 0.35)], startPoint: .topLeading, endPoint: .bottomTrailing),
            ]
            return gradients[index % gradients.count]
        } else {
            // Light mode: bright, vibrant colors
            let gradients: [LinearGradient] = [
                LinearGradient(colors: [.yellow.opacity(0.9), .yellow.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing),
                LinearGradient(colors: [Color(red: 0.3, green: 0.7, blue: 0.9), Color(red: 0.2, green: 0.6, blue: 0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
                LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.4), Color(red: 0.85, green: 0.4, blue: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                LinearGradient(colors: [Color(red: 0.5, green: 0.8, blue: 0.4), Color(red: 0.4, green: 0.7, blue: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                LinearGradient(colors: [Color(red: 0.8, green: 0.4, blue: 0.9), Color(red: 0.7, green: 0.3, blue: 0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
            ]
            return gradients[index % gradients.count]
        }
    }
    
    /// Returns a vibrant gradient for word practice based on index
    static func wordGradient(index: Int, colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            // Dark mode: darker backgrounds for white text
            let colors: [(Color, Color)] = [
                (Color(red: 0.5, green: 0.45, blue: 0.1), Color(red: 0.35, green: 0.3, blue: 0.07)),
                (Color(red: 0.5, green: 0.25, blue: 0.15), Color(red: 0.4, green: 0.15, blue: 0.1)),
                (Color(red: 0.15, green: 0.35, blue: 0.5), Color(red: 0.1, green: 0.25, blue: 0.35)),
                (Color(red: 0.25, green: 0.45, blue: 0.2), Color(red: 0.15, green: 0.3, blue: 0.1)),
                (Color(red: 0.45, green: 0.2, blue: 0.45), Color(red: 0.3, green: 0.15, blue: 0.3)),
                (Color(red: 0.5, green: 0.35, blue: 0.1), Color(red: 0.35, green: 0.2, blue: 0.05)),
            ]
            let pair = colors[index % colors.count]
            return LinearGradient(colors: [pair.0, pair.1], startPoint: .leading, endPoint: .trailing)
        } else {
            // Light mode: bright colors
            let colors: [(Color, Color)] = [
                (.yellow, Color(red: 0.7, green: 0.65, blue: 0.2)),
                (Color(red: 1.0, green: 0.6, blue: 0.4), Color(red: 0.9, green: 0.4, blue: 0.3)),
                (Color(red: 0.5, green: 0.85, blue: 1.0), Color(red: 0.3, green: 0.65, blue: 0.85)),
                (Color(red: 0.6, green: 0.9, blue: 0.5), Color(red: 0.4, green: 0.7, blue: 0.3)),
                (Color(red: 0.95, green: 0.6, blue: 0.95), Color(red: 0.75, green: 0.45, blue: 0.75)),
                (Color(red: 1.0, green: 0.7, blue: 0.3), Color(red: 0.8, green: 0.5, blue: 0.2)),
            ]
            let pair = colors[index % colors.count]
            return LinearGradient(colors: [pair.0, pair.1], startPoint: .leading, endPoint: .trailing)
        }
    }
}

// MARK: - Background Pattern View

struct EchoPatternBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                colors: colorScheme == .dark ? 
                    [Color(red: 0.12, green: 0.11, blue: 0.08), Color(red: 0.12, green: 0.11, blue: 0.08).opacity(0.8)] :
                    [Color(red: 0.95, green: 0.92, blue: 0.85), Color(red: 0.95, green: 0.92, blue: 0.85).opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle pattern overlay
            GeometryReader { geometry in
                Canvas { context, size in
                    let spacing: CGFloat = 40
                    let rows = Int(size.height / spacing) + 1
                    let cols = Int(size.width / spacing) + 1
                    
                    for row in 0..<rows {
                        for col in 0..<cols {
                            let x = CGFloat(col) * spacing
                            let y = CGFloat(row) * spacing
                            
                            var path = Path()
                            path.move(to: CGPoint(x: x, y: y))
                            path.addLine(to: CGPoint(x: x + 15, y: y + 15))
                            
                            context.stroke(
                                path,
                                with: .color(.yellow.opacity(colorScheme == .dark ? 0.08 : 0.12)),
                                lineWidth: 1.5
                            )
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

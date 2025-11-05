//
//  PieProgressView.swift
//  Echo
//
//  Created by Assistant on 2025-10-29.
//

import SwiftUI

struct PieProgressView: View {
    var fraction: Double // 0...1
    var lineWidth: CGFloat = 10
    var baseColor: Color = .gray.opacity(0.3)
    var fillColor: Color = .green // can be tied to accent/check color
    
    var body: some View {
        ZStack {
            // Base ring
            Circle()
                .stroke(baseColor, lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(1, fraction))))
                .stroke(fillColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: fraction)
            
            // Percentage text in center
            Text("\(Int(fraction * 100))%")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
        }
    }
}

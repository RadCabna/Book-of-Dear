//
//  Boom_2.swift
//  Book of Dead
//
//  Created by Алкександр Степанов on 14.10.2025.
//

import SwiftUI

struct Boom_2: View {
    @State private var currentSpriteIndex = 0
    @State private var opacity: Double = 1.0
    
    let spriteArray = ["boom2_1", "boom2_2", "boom2_3"]
    var onAnimationComplete: (() -> Void)?
    
    var body: some View {
        Image(spriteArray[currentSpriteIndex])
            .resizable()
            .scaledToFit()
            .frame(height: screenHeight*0.1)
            .opacity(opacity)
            .onAppear {
                startAnimation()
            }
    }
    
    func startAnimation() {
        animateNextFrame()
    }
    
    func animateNextFrame() {
        // Если дошли до последнего кадра
        if currentSpriteIndex >= spriteArray.count - 1 {
            // Плавно убираем opacity
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0.0
            }
            
            // Уведомляем о завершении анимации
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onAnimationComplete?()
            }
        } else {
            // Переходим к следующему кадру через 0.1 секунды
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                currentSpriteIndex += 1
                animateNextFrame()
            }
        }
    }
}

#Preview {
    Boom_2()
}


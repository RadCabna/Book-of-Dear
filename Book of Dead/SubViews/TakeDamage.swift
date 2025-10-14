//
//  TakeDamage.swift
//  Book of Dead
//
//  Created by Алкександр Степанов on 14.10.2025.
//

import SwiftUI

struct TakeDamage: View {
    @State private var damageOpacity: CGFloat = 0
    var body: some View {
        ZStack {
            Color.black
            Image(.warrior1)
                .resizable()
                .scaledToFit()
                .frame(height: screenHeight*0.2)
                .onTapGesture {
                    takeDamage()
                }
            Rectangle()
                .fill(Color.white)
                .frame(width: screenHeight*0.12, height: screenHeight*0.2)
                .mask(
                    Image(.warrior1)
                        .resizable()
                        .scaledToFit()
                        .frame(height: screenHeight*0.2)
                )
                .opacity(damageOpacity)
        }
    }
    
    func takeDamage() {
        damageOpacity = 1
        withAnimation(Animation.easeOut(duration: 0.5)) {
            damageOpacity = 0
        }
    }
    
}

#Preview {
    TakeDamage()
}

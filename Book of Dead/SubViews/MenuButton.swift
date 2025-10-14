//
//  MenuButton.swift
//  Book of Dead
//
//  Created by Алкександр Степанов on 15.10.2025.
//

import SwiftUI

struct MenuButton: View {
    var name = "PLAY"
    var size: CGFloat = 1
    var body: some View {
        Image(.buttonFrame)
            .resizable()
            .scaledToFit()
            .frame(height: screenHeight*0.08*size)
            .overlay(
                Text(name)
                    .font(Font.custom("AtomicAge-Regular", size: screenHeight*0.03))
                    .foregroundStyle(Color(.white))
                    .offset(y: screenHeight*0.004*size)
            )
    }
}

#Preview {
    MenuButton()
}

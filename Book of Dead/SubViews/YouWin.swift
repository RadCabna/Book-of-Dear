//
//  YouWin.swift
//  Book of Dead
//
//  Created by Алкександр Степанов on 14.10.2025.
//

import SwiftUI

struct YouWin: View {
    @AppStorage("score") var score = 0
    var body: some View {
        ZStack {
            Image(.winBG)
                .resizable()
                .ignoresSafeArea()
            HStack {
                VStack {
                    Image(.screFrame)
                        .resizable()
                        .scaledToFit()
                        .frame(height: screenHeight*0.03)
                        .overlay(
                            Text("\(score)")
                                .font(Font.custom("AtomicAge-Regular", size: screenHeight*0.02))
                                .foregroundStyle(Color.text1)
                                .offset(x: screenHeight*0.01)
                        )
                    Text("SCORE")
                        .font(Font.custom("AtomicAge-Regular", size: screenHeight*0.02))
                        .foregroundStyle(Color.white)
                        .offset(x: screenHeight*0.01)
                }
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.horizontal)
            VStack {
                Image(.win)
                    .resizable()
                    .scaledToFit()
                    .frame(height: screenHeight*0.5)
                Image(.plusScore)
                    .resizable()
                    .scaledToFit()
                    .frame(height: screenHeight*0.06)
                HStack {
                    Image(.menuButton)
                        .resizable()
                        .scaledToFit()
                        .frame(height: screenHeight*0.1)
                        .onTapGesture {
                            score += 250
                            NavGuard.shared.currentScreen = .MENU
                        }
                    Image(.nextButton)
                        .resizable()
                        .scaledToFit()
                        .frame(height: screenHeight*0.1)
                        .onTapGesture {
                            score += 250
                            NavGuard.shared.currentScreen = .MENU
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                                NavGuard.shared.currentScreen = .GAME
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    YouWin()
}

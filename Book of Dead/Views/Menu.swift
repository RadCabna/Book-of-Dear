//
//  Menu.swift
//  Book of Dead
//
//  Created by Алкександр Степанов on 07.10.2025.
//

import SwiftUI

struct Menu: View {
    @AppStorage("score") var score = 0
    @State private var yOffset: CGFloat = 0
    @State private var listOpacity: Double = 0
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
            ZStack {
                Image(.menuList)
                    .resizable()
                    .scaledToFit()
                    .frame(height: screenHeight*0.6)
                    .overlay(
                        VStack {
                            MenuButton()
                                .onTapGesture {
                                    NavGuard.shared.currentScreen = .GAME
                                }
                            MenuButton(name: "SHOP")
                                .onTapGesture {
                                    NavGuard.shared.currentScreen = .SHOP
                                }
                            MenuButton(name: "RECORD")
                                .onTapGesture {
                                    NavGuard.shared.currentScreen = .RECORDS
                                }
                            Image(.settingButton)
                                .resizable()
                                .scaledToFit()
                                .frame(height: screenHeight*0.08)
                                .onTapGesture {
                                    NavGuard.shared.currentScreen = .SETTINGS
                                }
                        }
                            .offset(y: screenHeight*0.07)
                    )
                    .offset(y: -screenHeight*0.55 + screenHeight*0.55*yOffset)
                    .mask(
                       Rectangle()
                            .frame(height: screenHeight*0.6)
                            .offset(y: screenHeight*0.075)
                    )
                Image(.topElement)
                    .resizable()
                    .scaledToFit()
                    .frame(height: screenHeight*0.15)
                    .offset(y: -screenHeight*0.22)
                HStack {
                    Image(.leftCorner)
                        .resizable()
                        .scaledToFit()
                        .frame(height: screenHeight*0.1)
                    Spacer()
                        .frame(width: screenHeight*0.2)
                    Image(.rightCorner)
                        .resizable()
                        .scaledToFit()
                        .frame(height: screenHeight*0.1)
                }
                .offset(y: screenHeight*0.26)
                .offset(y: -screenHeight*0.48 + screenHeight*0.48*yOffset)
            }
            .opacity(listOpacity)
        }
        
        .onAppear {
            animation()
            // Воспроизводим музыку при входе в меню (только если она не играет)
            // Небольшая задержка, чтобы убедиться, что переход завершен
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if !SoundManager.shared.isMusicPlaying {
                    SoundManager.shared.playMusic("music", loop: true)
                }
            }
        }
        .onDisappear {
            // НЕ останавливаем музыку при выходе из меню, если переходим в игру
            // Музыка будет остановлена только при явной остановке игры
        }
        
    }
    
    func animation() {
        withAnimation(Animation.easeInOut(duration: 1)) {
            listOpacity = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(Animation.easeInOut(duration: 1)) {
                yOffset = 1
            }
        }
    }
    
}

#Preview {
    Menu()
}

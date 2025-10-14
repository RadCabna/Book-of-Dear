//
//  Loading.swift
//  Lady's Holl
//
//  Created by Алкександр Степанов on 17.09.2025.
//

import SwiftUI

struct Loading: View {
    @State private var logoOpacity: Double = 0
    @State private var circleAngle: Double = 0
    @State private var loadingProgress: Double = 0
    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let width = geometry.size.width
            let isLandscape = width > height
            if isLandscape {
                ZStack {
                    Image(.hLoadingBG)
                        .resizable()
                    VStack {
                        Image(.loadingLogo)
                            .resizable()
                            .scaledToFit()
                            .frame(height: height*0.6)
                        ZStack {
                            Image(.loadingBarBack)
                                .resizable()
                                .scaledToFit()
                                .frame(height: height*0.1)
                            Image(.loadingBarFront)
                                .resizable()
                                .scaledToFit()
                                .frame(height: height*0.065)
                                .offset(x: -width*0.3 + width*0.3*loadingProgress)
                                .mask(
                                    Image(.loadingBarFront)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: height*0.065)
                                )
                        }
                    }
                }
                .ignoresSafeArea()
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
            } else {
                ZStack {
                    Backgrounds(backgroundNumber: 0)
                    VStack {
                        Image(.loadingLogo)
                            .resizable()
                            .scaledToFit()
                            .frame(height: width*0.6)
                            .padding(.top, height*0.1)
                        Spacer()
                        Text("Loading...")
                            .font(Font.custom("AtomicAge-Regular", size: height*0.03))
                            .foregroundStyle(Color.white)
                        ZStack {
                            Image(.loadingBarBack)
                                .resizable()
                                .scaledToFit()
                                .frame(height: width*0.1)
                            Image(.loadingBarFront)
                                .resizable()
                                .scaledToFit()
                                .frame(height: width*0.065)
                                .offset(x: -width*0.3 + width*0.3*loadingProgress)
                                .mask(
                                    Image(.loadingBarFront)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: width*0.065)
                                )
                        }
                    }
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .onAppear {
            opacityAnimation()
            rotationAnimation()
            loadingProgressAnimation()
        }
        
    }
    
    func loadingProgressAnimation() {
        withAnimation(Animation.easeOut(duration: 3)) {
            loadingProgress = 1
        }
    }
    
    func opacityAnimation() {
        withAnimation(Animation.easeInOut(duration: 1)) {
            logoOpacity = 1
        }
    }
    
    func rotationAnimation() {
        withAnimation(Animation.easeInOut(duration: 1) .repeatForever(autoreverses: false)) {
            circleAngle = 360
        }
    }
    
}

#Preview {
    Loading()
}

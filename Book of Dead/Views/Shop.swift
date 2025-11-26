//
//  Shop.swift
//  Book of Dead
//
//  Created by Алкександр Степанов on 13.11.2025.
//

import SwiftUI

struct Shop: View {
    @AppStorage("score") var score = 0
    @AppStorage("selectedShopItem") var selectedShopItem: Int = 0
    @State private var shopItemsState: [Int] = [0, 0, 0, 0, 0] // 0 - не куплен, 1 - куплен, 2 - выбран
    
    private let itemPrice = 250
    
    var body: some View {
        ZStack {
            Image(.winBG)
                .resizable()
                .ignoresSafeArea()
            ZStack {
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
                Image(.backMenuButton)
                    .resizable()
                    .scaledToFit()
                    .frame(height: screenHeight*0.07)
                    .onTapGesture {
                        NavGuard.shared.currentScreen = .MENU
                    }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.horizontal)
            
            // Сетка товаров: 2-2-1
            VStack(spacing: 0) {
                // Первый ряд - 2 товара
                HStack(spacing: screenWidth*0.05) {
                    ShopItemView(
                        itemIndex: 0,
                        itemImageName: "shopItem_1",
                        state: shopItemsState[0],
                        price: itemPrice,
                        onTap: { handleItemTap(index: 0) }
                    )
                    ShopItemView(
                        itemIndex: 1,
                        itemImageName: "shopItem_2",
                        state: shopItemsState[1],
                        price: itemPrice,
                        onTap: { handleItemTap(index: 1) }
                    )
                }
                
                // Второй ряд - 2 товара
                HStack(spacing: screenWidth*0.05) {
                    ShopItemView(
                        itemIndex: 2,
                        itemImageName: "shopItem_3",
                        state: shopItemsState[2],
                        price: itemPrice,
                        onTap: { handleItemTap(index: 2) }
                    )
                    ShopItemView(
                        itemIndex: 3,
                        itemImageName: "shopItem_4",
                        state: shopItemsState[3],
                        price: itemPrice,
                        onTap: { handleItemTap(index: 3) }
                    )
                }
                
                // Третий ряд - 1 товар
                ShopItemView(
                    itemIndex: 4,
                    itemImageName: "shopItem_5",
                    state: shopItemsState[4],
                    price: itemPrice,
                    onTap: { handleItemTap(index: 4) }
                )
            }
        
        }
        .onAppear {
            loadShopItemsState()
        }
    }
    
    private func loadShopItemsState() {
        if let savedState = UserDefaults.standard.array(forKey: "shopItemsState") as? [Int] {
            shopItemsState = savedState
        } else {
            // Инициализация: первый товар выбран по умолчанию
            shopItemsState = [2, 0, 0, 0, 0]
            selectedShopItem = 0
            saveShopItemsState()
            return
        }
        
        // Если selectedShopItem не установлен, устанавливаем первый товар как выбранный
        if selectedShopItem < 0 {
            // Ищем первый выбранный товар
            if let firstSelectedIndex = shopItemsState.firstIndex(where: { $0 == 2 }) {
                selectedShopItem = firstSelectedIndex
            } else {
                // Если нет выбранного товара, выбираем первый
                shopItemsState[0] = 2
                selectedShopItem = 0
                saveShopItemsState()
            }
        } else {
            // Синхронизируем выбранный товар
            if selectedShopItem < shopItemsState.count {
                // Снимаем выбор со всех товаров
                for i in 0..<shopItemsState.count {
                    if shopItemsState[i] == 2 {
                        shopItemsState[i] = 1
                    }
                }
                // Устанавливаем выбранный товар
                shopItemsState[selectedShopItem] = 2
                saveShopItemsState()
            }
        }
    }
    
    private func saveShopItemsState() {
        UserDefaults.standard.set(shopItemsState, forKey: "shopItemsState")
    }
    
    private func handleItemTap(index: Int) {
        let currentState = shopItemsState[index]
        
        switch currentState {
        case 0: // Не куплен - покупка
            if score >= itemPrice {
                score -= itemPrice
                shopItemsState[index] = 1
                saveShopItemsState()
            }
        case 1: // Куплен, но не выбран - выбор
            // Снимаем выбор с предыдущего товара
            if selectedShopItem >= 0 && selectedShopItem < shopItemsState.count {
                shopItemsState[selectedShopItem] = 1
            }
            // Выбираем новый товар
            shopItemsState[index] = 2
            selectedShopItem = index
            saveShopItemsState()
        case 2: // Уже выбран - ничего не делаем
            break
        default:
            break
        }
    }
}

struct ShopItemView: View {
    let itemIndex: Int
    let itemImageName: String
    let state: Int // 0 - не куплен, 1 - куплен, 2 - выбран
    let price: Int
    let onTap: () -> Void
    
    private var statusText: String {
        switch state {
        case 0:
            return "BUY \(price)"
        case 1:
            return "SELECT"
        case 2:
            return "SELECTED"
        default:
            return "BUY \(price)"
        }
    }
    
    var body: some View {
        ZStack {
            // Фон товара
            Image("shopItemFrame")
                .resizable()
                .scaledToFit()
                .frame(width: screenWidth*0.35, height: screenHeight*0.2)
            
            // Изображение товара
            Image(itemImageName)
                .resizable()
                .scaledToFit()
                .frame(width: screenWidth*0.26, height: screenHeight*0.15)
            
            // Табличка с ценой/статусом
            VStack {
                Spacer()
                Image("shopPriseFrame")
                    .resizable()
                    .scaledToFit()
                    .frame(width: screenWidth*0.25, height: screenHeight*0.05)
                    .overlay(
                        Text(statusText)
                            .font(Font.custom("AtomicAge-Regular", size: screenHeight*0.018))
                            .foregroundStyle(Color.white)
                            .shadow(color: Color.black, radius: 2)
                    )
                    .offset(y: -screenHeight*0.02)
            }
        }
        .frame(maxHeight: screenHeight*0.2)
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    Shop()
}

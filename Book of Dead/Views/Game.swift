//
//  Game.swift
//  Book of Dead
//
//  Created by Алкександр Степанов on 07.10.2025.
//

import SwiftUI

// MARK: - Tablet Item Model
struct TabletItem: Identifiable {
    let id = UUID()
    let imageName: String
    var isVisible: Bool = true
}

// MARK: - Explosion Model
struct Explosion: Identifiable {
    let id = UUID()
    let type: ExplosionType
    let position: CGPoint
    
    enum ExplosionType {
        case boom1
        case boom2
    }
}

// MARK: - Warrior Model
struct Warrior: Identifiable {
    let id = UUID()
    let imageName: String
    let type: WarriorType
    var health: Int
    let maxHealth: Int
    var attack: Int
    var isAlive: Bool = true
    var opacity: Double = 1.0
    var damageFlashOpacity: Double = 0.0
    var attackOffset: CGFloat = 0.0
    let randomOffsetX: CGFloat
    let randomOffsetY: CGFloat
    
    enum WarriorType {
        case playerWarrior1
        case playerWarrior2
        case playerWarrior3
        case enemy1
        case enemy2
        
        var imageName: String {
            switch self {
            case .playerWarrior1: return "warrior_1"
            case .playerWarrior2: return "warrior_2"
            case .playerWarrior3: return "warrior_3"
            case .enemy1: return "enemy_1"
            case .enemy2: return "enemy_2"
            }
        }
        
        var isRanged: Bool {
            switch self {
            case .playerWarrior3, .enemy2:
                return true
            default:
                return false
            }
        }
        
        // Базовые характеристики
        var baseHealth: Int {
            switch self {
            case .playerWarrior1: return 300
            case .playerWarrior2: return 400
            case .playerWarrior3: return 250
            case .enemy1: return 300
            case .enemy2: return 250
            }
        }
        
        var baseAttack: Int {
            switch self {
            case .playerWarrior1: return 8
            case .playerWarrior2: return 12
            case .playerWarrior3: return 10
            case .enemy1: return 8
            case .enemy2: return 10
            }
        }
    }
}

// MARK: - Battle Result
enum BattleResult {
    case none
    case win
    case lose
}

// MARK: - Game View Model
class GameViewModel: ObservableObject {
    @Published var tablets: [TabletItem] = []
    @Published var showTabletSelection = true
    @Published var isPlayerTurn = true
    @Published var isProcessing = false
    @Published var playerWarriors: [Warrior] = []
    @Published var enemyWarriors: [Warrior] = []
    @Published var warriorsMovedToCenter = false
    @Published var battleStarted = false
    @Published var warriorSpacing: CGFloat = 0
    @Published var explosions: [Explosion] = []
    @Published var battleProgress: CGFloat = 0.0
    @Published var battleResult: BattleResult = .none
    
    private var selectedTabletsByPlayer: [String] = []
    private var selectedTabletsByEnemy: [String] = []
    private var explosionTimer: Timer?
    private var progressTimer: Timer?
    private var initialPlayerHealth: Int = 0
    private var initialEnemyHealth: Int = 0
    
    private let allTabletImages = [
        "atc1", "atc2", "atc3", "atc4", "atc5", "atc6", "atc7",
        "hp1", "hp2", "hp3", "hp4", "hp5", "hp6", "hp7"
    ]
    
    init() {
        setupRandomTablets()
        setupWarriors()
    }
    
    deinit {
        explosionTimer?.invalidate()
        explosionTimer = nil
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    // MARK: - Tablet Bonuses
    func getTabletAttackModifier(for tabletName: String) -> Double {
        switch tabletName {
        case "atc1": return -0.10  // -10%
        case "atc2": return -0.20  // -20%
        case "atc3": return -0.30  // -30%
        case "atc4": return -0.40  // -40%
        case "atc5": return -0.50  // атака в 2 раза меньше
        case "atc6": return -0.60  // -60%
        case "atc7": return -0.15  // -15%
        case "hp1": return 0.10    // +10%
        case "hp2": return 0.20    // +20%
        case "hp3": return 0.30    // +30%
        case "hp4": return 0.40    // +40%
        case "hp5": return 0.50    // +50%
        case "hp6": return 1.00    // атака в 2 раза больше (+100%)
        case "hp7": return 0.15    // +15%
        default: return 0.0
        }
    }
    
    func calculatePlayerAttackBonus() -> Double {
        var totalBonus = 0.0
        for tablet in selectedTabletsByPlayer {
            let modifier = getTabletAttackModifier(for: tablet)
            if modifier > 0 { // hp таблички дают бонус игроку
                totalBonus += modifier
            }
        }
        return totalBonus
    }
    
    func calculateEnemyAttackDebuff() -> Double {
        var totalDebuff = 0.0
        for tablet in selectedTabletsByPlayer {
            let modifier = getTabletAttackModifier(for: tablet)
            if modifier < 0 { // atc таблички уменьшают атаку врага
                totalDebuff += abs(modifier)
            }
        }
        return totalDebuff
    }
    
    func calculateEnemyAttackBonus() -> Double {
        var totalBonus = 0.0
        for tablet in selectedTabletsByEnemy {
            let modifier = getTabletAttackModifier(for: tablet)
            if modifier > 0 { // hp таблички дают бонус противнику
                totalBonus += modifier
            }
        }
        return totalBonus
    }
    
    func calculatePlayerAttackDebuff() -> Double {
        var totalDebuff = 0.0
        for tablet in selectedTabletsByEnemy {
            let modifier = getTabletAttackModifier(for: tablet)
            if modifier < 0 { // atc таблички уменьшают атаку игрока
                totalDebuff += abs(modifier)
            }
        }
        return totalDebuff
    }
    
    // MARK: - Start Battle
    func startBattle() {
        // Запускаем анимацию движения воинов к центру
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 2.5)) {
                self.warriorsMovedToCenter = true
                self.warriorSpacing = -20 // Воины чуть-чуть сжимаются друг к другу
            }
            
            // После того как воины сошлись - начинаем битву
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                self.battleStarted = true
                self.startFighting()
            }
        }
    }
    
    func startFighting() {
        // Записываем начальное здоровье команд
        initialPlayerHealth = playerWarriors.reduce(0) { $0 + $1.health }
        initialEnemyHealth = enemyWarriors.reduce(0) { $0 + $1.health }
        
        // Запускаем атаки для всех воинов с разными задержками
        startWarriorAttacks()
        // Запускаем генерацию взрывов
        startExplosions()
        // Запускаем отслеживание прогресса
        startProgressTracking()
    }
    
    // MARK: - Progress Tracking
    func startProgressTracking() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateBattleProgress()
        }
    }
    
    func updateBattleProgress() {
        // Подсчитываем текущее здоровье команд
        let currentPlayerHealth = playerWarriors.reduce(0) { $0 + $1.health }
        let currentEnemyHealth = enemyWarriors.reduce(0) { $0 + $1.health }
        
        // Вычисляем процент оставшегося здоровья для каждой команды
        let playerHealthPercent = initialPlayerHealth > 0 ? Double(currentPlayerHealth) / Double(initialPlayerHealth) : 0.0
        let enemyHealthPercent = initialEnemyHealth > 0 ? Double(currentEnemyHealth) / Double(initialEnemyHealth) : 0.0
        
        // Определяем проигрывающую команду (у кого меньше процент здоровья)
        let losingTeamHealthPercent = min(playerHealthPercent, enemyHealthPercent)
        
        // Прогресс = 1 - (оставшееся здоровье проигрывающей команды)
        battleProgress = CGFloat(1.0 - losingTeamHealthPercent)
        
        // Проверяем окончание битвы
        if currentPlayerHealth <= 0 || currentEnemyHealth <= 0 {
            battleProgress = 1.0
            progressTimer?.invalidate()
            progressTimer = nil
        }
    }
    
    // MARK: - Explosions
    func startExplosions() {
        // Генерируем взрывы каждые 0.3-0.7 секунд
        explosionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Проверяем, идет ли еще битва
            let playerAlive = self.playerWarriors.contains(where: { $0.isAlive })
            let enemyAlive = self.enemyWarriors.contains(where: { $0.isAlive })
            
            if playerAlive && enemyAlive {
                self.addRandomExplosion()
            } else {
                // Битва закончена - останавливаем генерацию взрывов
                self.explosionTimer?.invalidate()
                self.explosionTimer = nil
            }
        }
    }
    
    func addRandomExplosion() {
        // Случайный тип взрыва
        let explosionType: Explosion.ExplosionType = Bool.random() ? .boom1 : .boom2
        
        // Случайная позиция в зоне битвы (центр экрана)
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Позиция в зоне битвы (узкая зона вокруг воинов)
        let x = CGFloat.random(in: screenWidth * 0.35...screenWidth * 0.65)
        let y = CGFloat.random(in: screenHeight * 0.42...screenHeight * 0.58)
        
        let explosion = Explosion(
            type: explosionType,
            position: CGPoint(x: x, y: y)
        )
        
        explosions.append(explosion)
        
        // Удаляем взрыв через 1.5 секунды (длительность анимации)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.explosions.removeAll(where: { $0.id == explosion.id })
        }
    }
    
    // MARK: - Battle Logic
    func startWarriorAttacks() {
        // Запускаем атаки для воинов игрока
        for (index, warrior) in playerWarriors.enumerated() {
            if warrior.isAlive {
                let randomDelay = Double.random(in: 0.1...0.8)
                DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
                    self.performPlayerWarriorAttack(at: index)
                }
            }
        }
        
        // Запускаем атаки для воинов противника
        for (index, warrior) in enemyWarriors.enumerated() {
            if warrior.isAlive {
                let randomDelay = Double.random(in: 0.1...0.8)
                DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
                    self.performEnemyWarriorAttack(at: index)
                }
            }
        }
    }
    
    func performPlayerWarriorAttack(at index: Int) {
        guard index < playerWarriors.count, playerWarriors[index].isAlive else { return }
        
        // Находим случайного живого противника
        let aliveEnemyIndices = enemyWarriors.enumerated()
            .filter { $0.element.isAlive }
            .map { $0.offset }
        
        guard let targetIndex = aliveEnemyIndices.randomElement() else { return }
        
        let damage = playerWarriors[index].attack
        let screenHeight = UIScreen.main.bounds.height
        
        // Анимация выпада вперед (вверх к противнику)
        withAnimation(.easeOut(duration: 0.15)) {
            playerWarriors[index].attackOffset = -screenHeight * 0.02
        }
        
        // Возврат обратно
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.15)) {
                self.playerWarriors[index].attackOffset = 0.0
            }
        }
        
        // Анимация вспышки при получении урона
        enemyWarriors[targetIndex].damageFlashOpacity = 1.0
        withAnimation(.easeOut(duration: 0.5)) {
            enemyWarriors[targetIndex].damageFlashOpacity = 0.0
        }
        
        // Наносим урон
        enemyWarriors[targetIndex].health = max(0, enemyWarriors[targetIndex].health - damage)
        
        // Проверяем, умер ли противник
        if enemyWarriors[targetIndex].health <= 0 {
            withAnimation(.easeOut(duration: 0.5)) {
                enemyWarriors[targetIndex].opacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.enemyWarriors[targetIndex].isAlive = false
                self.checkBattleEnd()
            }
        }
        
        // Следующая атака через случайный интервал
        let nextAttackDelay = Double.random(in: 1.5...2.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + nextAttackDelay) {
            self.performPlayerWarriorAttack(at: index)
        }
    }
    
    func performEnemyWarriorAttack(at index: Int) {
        guard index < enemyWarriors.count, enemyWarriors[index].isAlive else { return }
        
        // Находим случайного живого воина игрока
        let alivePlayerIndices = playerWarriors.enumerated()
            .filter { $0.element.isAlive }
            .map { $0.offset }
        
        guard let targetIndex = alivePlayerIndices.randomElement() else { return }
        
        let damage = enemyWarriors[index].attack
        let screenHeight = UIScreen.main.bounds.height
        
        // Анимация выпада вперед (вниз к игроку)
        withAnimation(.easeOut(duration: 0.15)) {
            enemyWarriors[index].attackOffset = screenHeight * 0.02
        }
        
        // Возврат обратно
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.15)) {
                self.enemyWarriors[index].attackOffset = 0.0
            }
        }
        
        // Анимация вспышки при получении урона
        playerWarriors[targetIndex].damageFlashOpacity = 1.0
        withAnimation(.easeOut(duration: 0.5)) {
            playerWarriors[targetIndex].damageFlashOpacity = 0.0
        }
        
        // Наносим урон
        playerWarriors[targetIndex].health = max(0, playerWarriors[targetIndex].health - damage)
        
        // Проверяем, умер ли воин
        if playerWarriors[targetIndex].health <= 0 {
            withAnimation(.easeOut(duration: 0.5)) {
                playerWarriors[targetIndex].opacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.playerWarriors[targetIndex].isAlive = false
                self.checkBattleEnd()
            }
        }
        
        // Следующая атака через случайный интервал
        let nextAttackDelay = Double.random(in: 1.5...2.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + nextAttackDelay) {
            self.performEnemyWarriorAttack(at: index)
        }
    }
    
    func checkBattleEnd() {
        let playerAlive = playerWarriors.contains(where: { $0.isAlive })
        let enemyAlive = enemyWarriors.contains(where: { $0.isAlive })
        
        if !playerAlive {
            print("Поражение!")
            // Показываем экран поражения через небольшую задержку
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.battleResult = .lose
            }
        } else if !enemyAlive {
            print("Победа!")
            // Показываем экран победы через небольшую задержку
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.battleResult = .win
            }
        }
    }
    
    // MARK: - Warriors Setup
    func setupWarriors() {
        let screenHeight = UIScreen.main.bounds.height
        let offsetRange = screenHeight * 0.002
        
        // Генерируем 7 воинов игрока
        playerWarriors = (0..<7).map { _ in
            let warriorType = generatePlayerWarriorType()
            return Warrior(
                imageName: warriorType.imageName,
                type: warriorType,
                health: warriorType.baseHealth,
                maxHealth: warriorType.baseHealth,
                attack: warriorType.baseAttack,
                isAlive: true,
                opacity: 1.0,
                damageFlashOpacity: 0.0,
                attackOffset: 0.0,
                randomOffsetX: CGFloat.random(in: -offsetRange...offsetRange),
                randomOffsetY: CGFloat.random(in: -offsetRange...offsetRange)
            )
        }
        
        // Генерируем 7 воинов противника
        enemyWarriors = (0..<7).map { _ in
            let warriorType = generateEnemyWarriorType()
            return Warrior(
                imageName: warriorType.imageName,
                type: warriorType,
                health: warriorType.baseHealth,
                maxHealth: warriorType.baseHealth,
                attack: warriorType.baseAttack,
                isAlive: true,
                opacity: 1.0,
                damageFlashOpacity: 0.0,
                attackOffset: 0.0,
                randomOffsetX: CGFloat.random(in: -offsetRange...offsetRange),
                randomOffsetY: CGFloat.random(in: -offsetRange...offsetRange)
            )
        }
    }
    
    // Генерация типа воина игрока с вероятностями: warrior_1 (80%), warrior_2 (5%), warrior_3 (15%)
    private func generatePlayerWarriorType() -> Warrior.WarriorType {
        let random = Int.random(in: 1...100)
        
        if random <= 80 {
            return .playerWarrior1
        } else if random <= 85 {
            return .playerWarrior2
        } else {
            return .playerWarrior3
        }
    }
    
    // Генерация типа воина противника с вероятностями: enemy_1 (80%), enemy_2 (20%)
    private func generateEnemyWarriorType() -> Warrior.WarriorType {
        let random = Int.random(in: 1...100)
        
        if random <= 80 {
            return .enemy1
        } else {
            return .enemy2
        }
    }
    
    func setupRandomTablets() {
        let shuffled = allTabletImages.shuffled()
        tablets = Array(shuffled.prefix(6)).map { TabletItem(imageName: $0) }
        showTabletSelection = true
        isPlayerTurn = true
        isProcessing = false
        selectedTabletsByPlayer = []
        selectedTabletsByEnemy = []
    }
    
    func selectTablet(at index: Int) {
        guard isPlayerTurn && !isProcessing else { return }
        guard index < tablets.count && tablets[index].isVisible else { return }
        
        isProcessing = true
        
        // Запоминаем выбранную табличку игроком
        selectedTabletsByPlayer.append(tablets[index].imageName)
        
        // Убираем табличку игрока с анимацией
        withAnimation(.easeOut(duration: 0.3)) {
            tablets[index].isVisible = false
        }
        
        // Проверяем, остались ли видимые таблички
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if self.tablets.allSatisfy({ !$0.isVisible }) {
                // Все таблички выбраны - применяем бонусы и закрываем оверлей
                self.applyTabletBonuses()
                withAnimation(.easeOut(duration: 0.5)) {
                    self.showTabletSelection = false
                }
                self.isProcessing = false
                // Запускаем битву
                self.startBattle()
            } else {
                // Ход противника
                self.isPlayerTurn = false
                self.opponentTurn()
            }
        }
    }
    
    func opponentTurn() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Находим случайную видимую табличку
            let visibleIndices = self.tablets.enumerated()
                .filter { $0.element.isVisible }
                .map { $0.offset }
            
            if let randomIndex = visibleIndices.randomElement() {
                // Запоминаем выбранную табличку противником
                self.selectedTabletsByEnemy.append(self.tablets[randomIndex].imageName)
                
                withAnimation(.easeOut(duration: 0.3)) {
                    self.tablets[randomIndex].isVisible = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if self.tablets.allSatisfy({ !$0.isVisible }) {
                        // Все таблички выбраны - применяем бонусы и закрываем оверлей
                        self.applyTabletBonuses()
                        withAnimation(.easeOut(duration: 0.5)) {
                            self.showTabletSelection = false
                        }
                        self.isProcessing = false
                        // Запускаем битву
                        self.startBattle()
                    } else {
                        // Передаем ход игроку
                        self.isPlayerTurn = true
                        self.isProcessing = false
                    }
                }
            }
        }
    }
    
    // MARK: - Apply Tablet Bonuses
    func applyTabletBonuses() {
        let playerBonus = calculatePlayerAttackBonus()
        let playerDebuff = calculatePlayerAttackDebuff()
        let enemyBonus = calculateEnemyAttackBonus()
        let enemyDebuff = calculateEnemyAttackDebuff()
        
        // Применяем бонусы к воинам игрока
        playerWarriors = playerWarriors.map { warrior in
            let baseAttack = Double(warrior.type.baseAttack)
            let bonusAttack = baseAttack * playerBonus
            let debuffAttack = baseAttack * playerDebuff
            let finalAttack = Int(baseAttack + bonusAttack - debuffAttack)
            
            var updatedWarrior = warrior
            updatedWarrior.attack = max(1, finalAttack)
            return updatedWarrior
        }
        
        // Применяем бонусы к воинам противника
        enemyWarriors = enemyWarriors.map { warrior in
            let baseAttack = Double(warrior.type.baseAttack)
            let bonusAttack = baseAttack * enemyBonus
            let debuffAttack = baseAttack * enemyDebuff
            let finalAttack = Int(baseAttack + bonusAttack - debuffAttack)
            
            var updatedWarrior = warrior
            updatedWarrior.attack = max(1, finalAttack)
            return updatedWarrior
        }
        
        print("🎴 Игрок выбрал: \(selectedTabletsByPlayer)")
        print("⚔️ Бонус атаки игрока: +\(Int(playerBonus * 100))%, Дебафф: -\(Int(playerDebuff * 100))%")
        print("🎴 Противник выбрал: \(selectedTabletsByEnemy)")
        print("⚔️ Бонус атаки противника: +\(Int(enemyBonus * 100))%, Дебафф: -\(Int(enemyDebuff * 100))%")
    }
}

struct Game: View {
    @AppStorage("bgNumber") var bgNumber: Int = 2
    @AppStorage("score") var score = 0
    @StateObject private var viewModel = GameViewModel()
    
    var body: some View {
        ZStack {
        VStack {
            Backgrounds(backgroundNumber: bgNumber)
            }
            
            VStack {
                Spacer()
                    .frame(height: screenHeight * 0.35)
                
                HStack(spacing: viewModel.warriorSpacing) {
                    ForEach(viewModel.enemyWarriors) { warrior in
                        WarriorView(warrior: warrior, isEnemy: true)
                            .environmentObject(viewModel)
                    }
                }
                .offset(y: viewModel.warriorsMovedToCenter ? (screenHeight * 0.1) : 0)
                
                Spacer()
            }
            
            // Воины игрока (внизу экрана)
            VStack {
                Spacer()
                
                HStack(spacing: viewModel.warriorSpacing) {
                    ForEach(viewModel.playerWarriors) { warrior in
                        WarriorView(warrior: warrior, isEnemy: false)
                            .environmentObject(viewModel)
                    }
                }
                .offset(y: viewModel.warriorsMovedToCenter ? (-screenHeight * 0.1) : 0)
                .padding(.bottom, screenHeight * 0.15)
            }
            
            // Взрывы
            ForEach(viewModel.explosions) { explosion in
                Group {
                    if explosion.type == .boom1 {
                        Boom_1(onAnimationComplete: {
                            // Взрыв завершен, он будет удален автоматически
                        })
                    } else {
                        Boom_2(onAnimationComplete: {
                            // Взрыв завершен, он будет удален автоматически
                        })
                    }
                }
                .position(explosion.position)
            }
            
            ZStack {
                Image(.backMenuButton)
                    .resizable()
                    .scaledToFit()
                    .frame(height: screenHeight*0.07)
                    .onTapGesture {
                        NavGuard.shared.currentScreen = .MENU
                    }
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
                            .foregroundStyle(Color.text2)
                            .offset(x: screenHeight*0.01)
                    }
                    Spacer()
                    VStack {
                        Image(.progressBarBack)
                            .resizable()
                            .scaledToFit()
                            .frame(height: screenHeight*0.03)
                            .overlay(
                                ZStack {
                                    Image(.progressBarFront)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: screenHeight*0.022)
                                        .offset(x: -screenWidth*0.3 + screenWidth*0.3*viewModel.battleProgress)
                                        .mask(
                                            Image(.progressBarFront)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: screenHeight*0.022)
                                        )
                                    Image(.progressIcon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: screenHeight*0.02)
                                        .offset(x: -screenHeight*0.05)
                                }
                            )
                        Text("PROGRESS")
                            .font(Font.custom("AtomicAge-Regular", size: screenHeight*0.02))
                            .foregroundStyle(Color.text2)
                            .offset(x: screenHeight*0.01)
                    }
                }
                .padding(.horizontal)
                .offset(y: screenHeight*0.01)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            
            // Оверлей с выбором табличек
            if viewModel.showTabletSelection {
                TabletSelectionOverlay(viewModel: viewModel)
            }
        }
        .fullScreenCover(isPresented: .constant(viewModel.battleResult == .win)) {
            YouWin()
        }
        .fullScreenCover(isPresented: .constant(viewModel.battleResult == .lose)) {
            YouLose()
        }
    }
}

// MARK: - Tablet Selection Overlay
struct TabletSelectionOverlay: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        ZStack {
            
         
            
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Сетка табличек
            VStack(spacing: 20) {
//                Text(viewModel.isPlayerTurn ? "Ваш ход" : "Ход противника")
//                    .font(.custom("Sora-ExtraBold", size: 28))
//                    .foregroundColor(.white)
//                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
//                    .padding(.bottom, 20)
//                
                VStack(spacing: 15) {
                    // Первый ряд (3 таблички)
                    HStack(spacing: 15) {
                        ForEach(0..<3) { index in
                            if index < viewModel.tablets.count {
                                TabletView(
                                    tablet: viewModel.tablets[index],
                                    onTap: {
                                        viewModel.selectTablet(at: index)
                                    }
                                )
                            }
                        }
                    }
                    
                    // Второй ряд (3 таблички)
                    HStack(spacing: 15) {
                        ForEach(3..<6) { index in
                            if index < viewModel.tablets.count {
                                TabletView(
                                    tablet: viewModel.tablets[index],
                                    onTap: {
                                        viewModel.selectTablet(at: index)
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Tablet View
struct TabletView: View {
    let tablet: TabletItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            if tablet.isVisible {
                Image(tablet.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            } else {
                Color.clear
                    .frame(width: 100, height: 100)
            }
        }
        .disabled(!tablet.isVisible)
    }
}

// MARK: - Warrior View
struct WarriorView: View {
    let warrior: Warrior
    let isEnemy: Bool
    @EnvironmentObject var viewModel: GameViewModel
    
    var body: some View {
        ZStack {
            // Воин
            if warrior.opacity > 0 {
                Image(warrior.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: UIScreen.main.bounds.height * 0.12)
                    .opacity(warrior.opacity)
            } else {
                Color.clear
                    .frame(height: UIScreen.main.bounds.height * 0.12)
            }
            
            // Вспышка урона (белый прямоугольник с маской)
            if warrior.opacity > 0 {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: UIScreen.main.bounds.width * 0.12, height: UIScreen.main.bounds.height * 0.12)
                    .mask(
                        Image(warrior.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: UIScreen.main.bounds.height * 0.12)
                    )
                    .opacity(warrior.damageFlashOpacity)
            }
            
            // Полоска здоровья для противников (сверху)
            if isEnemy && warrior.health > 0 {
                healthBar
                    .offset(y: -UIScreen.main.bounds.height * 0.065)
            }
            
            // Полоска здоровья для игроков (снизу)
            if !isEnemy && warrior.health > 0 {
                healthBar
                    .offset(y: UIScreen.main.bounds.height * 0.065)
            }
        }
        .frame(width: UIScreen.main.bounds.width * 0.12, height: UIScreen.main.bounds.height * 0.12)
        .offset(
            x: warrior.randomOffsetX,
            y: archerOffset + warrior.attackOffset + warrior.randomOffsetY
        )
    }
    
    private var healthBar: some View {
        let barWidth = UIScreen.main.bounds.width * 0.1
        let healthWidth = barWidth * CGFloat(warrior.health) / CGFloat(warrior.maxHealth)
        
        return ZStack(alignment: .leading) {
            // Фон полоски
            Rectangle()
                .fill(Color.black.opacity(0.5))
                .frame(width: barWidth, height: 4)
                .cornerRadius(2)
            
            // Заполнение здоровья
            Rectangle()
                .fill(healthColor)
                .frame(width: healthWidth, height: 4)
                .cornerRadius(2)
        }
        .frame(height: 4)
    }
    
    private var healthColor: Color {
        let healthPercent = Double(warrior.health) / Double(warrior.maxHealth)
        if healthPercent > 0.6 {
            return .green
        } else if healthPercent > 0.3 {
            return .orange
        } else {
            return .red
        }
    }
    
    // Лучники должны немного не доходить до центра
    private var archerOffset: CGFloat {
        guard viewModel.warriorsMovedToCenter else { return 0 }
        
        if warrior.type.isRanged {
            // Лучники останавливаются дальше от центра
            return isEnemy ? -30 : 30
        }
        return 0
    }
}

#Preview {
    Game()
}

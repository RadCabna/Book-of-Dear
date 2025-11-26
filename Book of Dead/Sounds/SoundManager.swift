

import Foundation
import AVFoundation

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    // Плееры для звуков
    private var soundPlayers: [String: AVAudioPlayer] = [:]
    private var soundBaseVolumes: [String: Float] = [:] // Базовая громкость каждого эффекта (0.0-1.0)
    private var musicPlayer: AVAudioPlayer?
    
    // Настройки громкости
    @Published var effectsVolume: Double = 1.0 {
        didSet {
            updateEffectsVolume()
        }
    }
    
    @Published var musicVolume: Double = 1.0 {
        didSet {
            updateMusicVolume()
        }
    }
    
    private init() {
        // Загружаем настройки громкости из UserDefaults
        // Проверяем, существует ли ключ. Если нет - используем 1.0 по умолчанию
        if UserDefaults.standard.object(forKey: "effectsVolume") != nil {
            effectsVolume = UserDefaults.standard.double(forKey: "effectsVolume")
        } else {
            effectsVolume = 1.0
        }
        
        if UserDefaults.standard.object(forKey: "musicVolume") != nil {
            musicVolume = UserDefaults.standard.double(forKey: "musicVolume")
        } else {
            musicVolume = 0.0 // Музыка выключена по умолчанию
        }
        
        // Настраиваем аудиосессию
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Ошибка настройки аудиосессии: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Звуковые эффекты
    
    /// Воспроизводит звуковой эффект с учетом настроек громкости
    /// - Parameters:
    ///   - soundName: Имя звукового файла (без расширения)
    ///   - volume: Дополнительный множитель громкости (0.0 - 1.0), по умолчанию 1.0
    func playEffect(_ soundName: String, volume: Float = 1.0) {
        guard effectsVolume > 0 else { return }
        
        // Сохраняем базовую громкость эффекта
        soundBaseVolumes[soundName] = volume
        
        // Проверяем, есть ли уже загруженный плеер для этого звука
        if let player = soundPlayers[soundName] {
            player.volume = Float(effectsVolume) * volume
            player.currentTime = 0
            player.play()
            return
        }
        
        // Загружаем новый звук
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") ??
                       Bundle.main.url(forResource: soundName, withExtension: "wav") ??
                       Bundle.main.url(forResource: soundName, withExtension: "m4a") else {
            print("⚠️ Звуковой файл не найден: \(soundName)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = Float(effectsVolume) * volume
            player.prepareToPlay()
            soundPlayers[soundName] = player
            player.play()
        } catch {
            print("Ошибка воспроизведения звука \(soundName): \(error.localizedDescription)")
        }
    }
    
    /// Останавливает конкретный звуковой эффект
    func stopEffect(_ soundName: String) {
        soundPlayers[soundName]?.stop()
    }
    
    /// Останавливает все звуковые эффекты
    func stopAllEffects() {
        soundPlayers.values.forEach { $0.stop() }
    }
    
    // MARK: - Музыка
    
    /// Воспроизводит музыку с учетом настроек громкости
    /// - Parameters:
    ///   - musicName: Имя музыкального файла (без расширения)
    ///   - loop: Зациклить ли музыку, по умолчанию true
    func playMusic(_ musicName: String, loop: Bool = true) {
        guard musicVolume > 0 else { return }
        
        // Останавливаем предыдущую музыку, если она играет
        stopMusic()
        
        guard let url = Bundle.main.url(forResource: musicName, withExtension: "mp3") ??
                       Bundle.main.url(forResource: musicName, withExtension: "wav") ??
                       Bundle.main.url(forResource: musicName, withExtension: "m4a") else {
            print("⚠️ Музыкальный файл не найден: \(musicName)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = Float(musicVolume)
            player.numberOfLoops = loop ? -1 : 0
            player.prepareToPlay()
            musicPlayer = player
            player.play()
        } catch {
            print("Ошибка воспроизведения музыки \(musicName): \(error.localizedDescription)")
        }
    }
    
    /// Останавливает музыку
    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }
    
    /// Приостанавливает музыку
    func pauseMusic() {
        musicPlayer?.pause()
    }
    
    /// Возобновляет музыку
    func resumeMusic() {
        musicPlayer?.play()
    }
    
    /// Проверяет, играет ли музыка
    var isMusicPlaying: Bool {
        return musicPlayer?.isPlaying ?? false
    }
    
    // MARK: - Обновление громкости
    
    /// Обновляет громкость всех звуковых эффектов
    private func updateEffectsVolume() {
        for (soundName, player) in soundPlayers {
            if let baseVolume = soundBaseVolumes[soundName] {
                player.volume = Float(effectsVolume) * baseVolume
            }
        }
    }
    
    /// Обновляет громкость музыки
    private func updateMusicVolume() {
        musicPlayer?.volume = Float(musicVolume)
    }
    
    /// Обновляет настройки громкости из UserDefaults (вызывается при изменении настроек)
    func updateVolumes() {
        if UserDefaults.standard.object(forKey: "effectsVolume") != nil {
            let newEffectsVolume = UserDefaults.standard.double(forKey: "effectsVolume")
            if newEffectsVolume != effectsVolume {
                effectsVolume = newEffectsVolume
            }
        }
        
        if UserDefaults.standard.object(forKey: "musicVolume") != nil {
            let newMusicVolume = UserDefaults.standard.double(forKey: "musicVolume")
            if newMusicVolume != musicVolume {
                musicVolume = newMusicVolume
            }
        }
    }
}

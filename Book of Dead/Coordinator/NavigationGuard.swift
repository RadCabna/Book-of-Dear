import Foundation


enum AvailableScreens {
    case MENU
    case GAME
    case SHOP
    case SETTINGS
    case RECORDS
}

class NavGuard: ObservableObject {
    @Published var currentScreen: AvailableScreens = .MENU
    static var shared: NavGuard = .init()
}

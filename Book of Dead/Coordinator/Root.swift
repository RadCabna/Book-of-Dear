import SwiftUI

enum LoaderStatus {
    case LOADING
    case DONE
    case ERROR
}



enum Screen {
    case MENU
    case GAME
}

class OrientationManager: ObservableObject  {
    @Published var isHorizontalLock = true
    
    static var shared: OrientationManager = .init()
}

struct RootView: View {
    @State private var status: LoaderStatus = .LOADING
    @ObservedObject private var nav: NavGuard = NavGuard.shared
    let url: URL = URL(string: "https://barstowflow.com/settings?page=test")!
    
    @ObservedObject private var orientationManager: OrientationManager = OrientationManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if status != .DONE {
                    switch nav.currentScreen {
                    case .MENU:
                        Menu()
                    case .GAME:
                        Game()
                    case .SHOP:
                        Shop()
                    case .SETTINGS:
                        Settings()
                    case .RECORDS:
                        Records()
                    }
                }
            
                switch status {
                case .LOADING:
                    Loading()
                        .edgesIgnoringSafeArea(.all)
                case .DONE:
                    ZStack {
                        Color.black
                            .edgesIgnoringSafeArea(.all)
                        
                        GameLoader_1E6704B4Overlay(data: .init(url: url))
                    }
                        
                case .ERROR:
                    Text("")
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }

        .onAppear {
            Task {
                let result = await GameLoader_1E6704B4StatusChecker().checkStatus(url: url)
                if result {
                    self.status = .DONE
                } else {
                    self.status = .ERROR
                }
                print(result)
            }
        }
    }
}



#Preview {
    RootView()
}

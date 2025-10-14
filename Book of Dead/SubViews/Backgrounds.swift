import SwiftUI

struct Backgrounds: View {
    var backgroundNumber = 0
    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let width = geometry.size.width
            let isLandscape = width > height
            if isLandscape {
                Image(whatBG())
                    .resizable()
                    .frame(width: height*1.2, height: width)
                    .rotationEffect(Angle(degrees: -90))
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            } else {
                Image(whatBG())
                    .resizable()
                    .frame(width: width, height: height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .ignoresSafeArea()
    }
    
    func whatBG() -> String{
        switch backgroundNumber {
        case 0:
            return "vLoadingBG"
        case 1:
            return "hLoadingBG"
        case 2:
            return "gameBG_1"
        case 3:
            return "gameBG_2"
        case 4:
            return "gameBG_3"
        case 5:
            return "gameBG_4"
        default:
            return "background1"
        }
    }
}

#Preview {
    Backgrounds()
}

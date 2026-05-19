import SwiftUI

// ====== Colors ======

struct Theme {

    static let brand = Color("Colors/Brand")
    static let background = Color("Colors/Background")
    static let surface = Color("Colors/Surface")
    static let muted = Color("Colors/Muted")
    static let inputBackground = Color("Colors/InputBackground")
    static let gradientTop = Color("Colors/GradientTop")
    static let gradientBottom = Color("Colors/GradientBottom")
    static let gradientMid = Color("Colors/GradientMid")

    // ====== Gradients ======

    static let appBackground = LinearGradient(
        stops: [
            .init(color: Color("Colors/InputBackground"), location: 0.0),
            .init(color: Color("Colors/GradientBottom"), location: 0.29),
            .init(color: Color("Colors/GradientMid"), location: 0.67),
            .init(color: Color("Colors/Surface"), location: 1.0),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

}

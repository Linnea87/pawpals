import SwiftUI

// ====== Colors ======

struct Theme {

    // Titles, body text and menu lines
    static let darkBrown = Color("Colors/DarkBrown")

    // Location text and location icon
    static let warmBrown = Color("Colors/WarmBrown")

    // Sign in, Sign up with Google and link text
    static let creamWhite = Color("Colors/CreamWhite")

    // Input and card backgrounds, button text, active text and icons (including tab bar), photo placeholder icon
    static let offWhite = Color("Colors/OffWhite")

    // Button backgrounds — Sign in, Sign up, Save, Start chat, etc.
    static let terracotta = Color("Colors/Terracotta")

    // Photo card placeholder circle
    static let lightPeach = Color("Colors/LightPeach")

    // Inactive tab bar icons and text, walk preference tag backgrounds, filter button backgrounds in Chat and Meet
    static let sageGreen = Color("Colors/SageGreen")

    // Gradient stops — app background
    static let palePeach = Color("Colors/PalePeach")
    static let lightSage = Color("Colors/LightSage")
    static let mediumSage = Color("Colors/MediumSage")

    // ====== Gradients ======

    // App background gradient — top to bottom
    static let appBackground = LinearGradient(
        stops: [
            .init(color: Color("Colors/CreamWhite"), location: 0.0),
            .init(color: Color("Colors/MediumSage"), location: 0.29),
            .init(color: Color("Colors/LightSage"), location: 0.67),
            .init(color: Color("Colors/PalePeach"), location: 1.0),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

   

}

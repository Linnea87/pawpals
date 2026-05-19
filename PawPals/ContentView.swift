import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Theme.appBackground
                .ignoresSafeArea()
        }
    }
}


#Preview {
    ContentView()
}

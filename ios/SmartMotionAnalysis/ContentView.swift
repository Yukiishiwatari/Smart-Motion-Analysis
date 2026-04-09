import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        LocalWebAppView()
            .ignoresSafeArea()
            .onAppear(perform: requestPortraitIfPossible)
    }

    private func requestPortraitIfPossible() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }

        if #available(iOS 16.0, *) {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }
}

#Preview {
    ContentView()
}

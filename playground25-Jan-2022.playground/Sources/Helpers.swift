import Foundation
import SwiftUI
import UIKit

public func assert(_ condition: @autoclosure () -> Bool) -> String {
    return condition() ? "✅" : "❌"
}

public struct ToSwiftUI: UIViewControllerRepresentable {
    
    let viewController: () -> UIViewController
    
    public init(viewController: @escaping () -> UIViewController) {
        self.viewController = viewController
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        self.viewController()
    }
    
    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}



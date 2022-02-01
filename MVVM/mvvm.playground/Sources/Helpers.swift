import Combine
import Foundation
import SwiftUI
import UIKit
import XCTestDynamicOverlay

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

extension AnyPublisher {
    public static func failing(_ message: String = "") -> Self {
        .fireAndForget {
            XCTFail("\(message.isEmpty ? "" : "\(message) - ")A failing effect ran.")
        }
    }

    public init(value: Output) {
        self = Just(value).setFailureType(to: Failure.self).eraseToAnyPublisher()
    }

    public init(_ error: Failure) {
        self = Fail(error: error).eraseToAnyPublisher()
    }

    public static func fireAndForget(_ work: @escaping () -> Void) -> Self {
        Deferred { () -> Empty<Output, Failure> in
            work()
            return Empty(completeImmediately: true)
        }.eraseToAnyPublisher()
    }
}



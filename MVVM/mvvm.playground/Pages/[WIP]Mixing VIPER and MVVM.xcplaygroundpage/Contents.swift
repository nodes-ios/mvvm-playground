//: [Previous](@previous)

import Foundation
import Combine
import CombineSchedulers
import PlaygroundSupport
import UIKit
import SwiftUI

/// All of this is VIPER-infrastructure
protocol APIRepository {
    func login(email: String, password: String) -> AnyPublisher<Void, Error>
}

protocol SystemDependenciesProtocol {
    var mainQueue: AnySchedulerOf<DispatchQueue> { get }
}

typealias FullDependencies = APIRepository & SystemDependenciesProtocol

class MockDependencies {}

extension MockDependencies: APIRepository {
    func login(email: String, password: String) -> AnyPublisher<Void, Error> {
        Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

extension MockDependencies: SystemDependenciesProtocol {
    var mainQueue: AnySchedulerOf<DispatchQueue> {
        DispatchQueue.main.eraseToAnyScheduler()
    }
}

/// Viper Coordinator that wants to display a SwiftUI view built with MVVM
class LoginCoordinator: Coordinator {
    
    var dependencies: FullDependencies
    var children: [Coordinator] = []
    let navController: UINavigationController
    
    init(
        navController: UINavigationController,
        dependencies: FullDependencies
    ) {
        self.dependencies = dependencies
        self.navController = navController
    }
    
    func start() {
        
        let rootVC = UIHostingController(
            rootView: LoginView(
                viewModel: LoginViewModel(
                    environment: .init(
                        mainQueue: dependencies.mainQueue,
                        apiClient: APIClient(
                            login: { [dependencies] request in
                                dependencies.login(
                                    email: request.email,
                                    password: request.password
                                )
                            }
                        )
                    )
                )
            )
        )
        navController.viewControllers = [rootVC]
    }
}

let nav = UINavigationController()
nav.view.frame = CGRect(x: 0, y: 0, width: 380, height: 667)

let coordinator = LoginCoordinator(
    navController: nav,
    dependencies: MockDependencies()
)
coordinator.start()

PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundPage.current.setLiveView(nav)

//: [Next](@next)

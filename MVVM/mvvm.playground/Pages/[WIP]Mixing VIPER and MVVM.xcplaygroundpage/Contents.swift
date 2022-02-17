//: [Previous](@previous)

import Foundation
import Combine

protocol APIRepository {
    func login(email: String, password: String) -> AnyPublisher<Void, Error>
}

class LoginCoordinator: Coordinator {
    
    
    
    var children: [Coordinator] = []
    
    func start() {
        
    }
}

//: [Next](@next)

//: [Previous](@previous)

import Foundation

var greeting = "Hello, playground"

Task {
    let c1 = ContinuousClock()
    let d1 = Date()
    
    print(c1.now)
    print(d1.timeIntervalSince1970)
}

//: [Next](@next)

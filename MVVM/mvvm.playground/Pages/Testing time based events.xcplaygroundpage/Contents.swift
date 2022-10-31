//: [Previous](@previous)

import Combine
import CombineSchedulers
import Foundation
import PlaygroundSupport
import SwiftUI
import XCTest
import Clocks

/// Let's suppose we have an Onboarding screen with a carousel that
/// automatically shows the next view after a small delay of N seconds.
@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var cards: [String]
    @Published var currentIndex: Int
    private let clock: any Clock<Duration>
    private var task: Task<Void, Error>?
    
    var currentCard: String? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }
    
    init(items: [String], clock: any Clock<Duration>) {
        self.cards = items
        self.currentIndex = 0
        self.clock = clock
    }
    
    func start() {
        task = Task {
            while true {
                try await clock.sleep(for: .seconds(1))
                currentIndex = (currentIndex + 1) % cards.count
            }
        }
    }
    
    func stop() {
        task?.cancel()
        task = nil
    }
}

// MARK: - Tests -
@MainActor
class OnboardingViewModelTestCase: XCTestCase {
    func testCarousel() async {
        let items = ["One", "Two", "Three", "Four", "Five"]
        let clock = TestClock()
        let viewModel = OnboardingViewModel(items: items, clock: clock)
        
        // When the view model gets initialized it should show the first element
        XCTAssertEqual(viewModel.currentCard, items[0])
        
        // Even if 10 seconds pass, it should still show the first element since
        // we haven't started the carousel
        await clock.advance(by: .seconds(10))
        XCTAssertEqual(viewModel.currentCard, items[0])
        
        // After 0.5s the carousel we should still see the 1st element
        viewModel.start()
        await clock.advance(by: .seconds(0.5))
        XCTAssertEqual(viewModel.currentCard, items[0])
        
        // But after further 0.6 (1.1s) we should see the 2nd element
        await clock.advance(by: .seconds(0.6))
        XCTAssertEqual(viewModel.currentCard, items[1])
        
        // 3 seconds later we should see the last element
        await clock.advance(by: .seconds(3))
        XCTAssertEqual(viewModel.currentCard, items[4])
        
        // 2 seconds later it should go back to the 2nd element
        await clock.advance(by: .seconds(2))
        XCTAssertEqual(viewModel.currentCard, items[1])
        
        // After we stop the carousel, it should still show the 2nd element
        viewModel.stop()
        await clock.advance(by: .seconds(3))
        XCTAssertEqual(viewModel.currentCard, items[1])
        await clock.advance(by: .seconds(1))
        XCTAssertEqual(viewModel.currentCard, items[1])
        
        // After resuming the carousel it should show the same element as before
        viewModel.start()
        
        XCTAssertEqual(viewModel.currentCard, items[1])
        await clock.advance(by: .seconds(1.3))
        XCTAssertEqual(viewModel.currentCard, items[2])
    }
}

// And run the tests
OnboardingViewModelTestCase.defaultTestSuite.run()

//: [Next](@next)




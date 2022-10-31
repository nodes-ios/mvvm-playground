//: [Previous](@previous)

import Combine
import CombineSchedulers
import Foundation
import PlaygroundSupport
import SwiftUI
import XCTest
import Clocks

/// Let's suppose we have an Onboarding screen with a carousel that
/// automatically shows the next view after a small delay of 5 seconds.
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
                try await clock.sleep(for: .seconds(5))
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
class OnboardingViewModelTestCase: XCTestCase {
    func testCarousel() async {
        let items = ["One", "Two", "Three", "Four", "Five"]
        let clock = TestClock()
        let viewModel = OnboardingViewModel(items: items, clock: clock)
        
        // When the view model gets initialized it should show the first element
        XCTAssertEqual(viewModel.currentCard, items[0])
        
        // Even if 50 seconds pass, it should still show the first element since
        // we haven't started the carousel
        await clock.advance(by: .seconds(50))
        XCTAssertEqual(viewModel.currentCard, items[0])
        
        // After 2.5s the carousel we should still see the 1st element
        viewModel.start()
        await clock.advance(by: .seconds(2.5))
        XCTAssertEqual(viewModel.currentCard, items[0])
        
        // But after further 2.6 (5.1s) we should see the 2nd element
        await clock.advance(by: .seconds(2.6))
        XCTAssertEqual(viewModel.currentCard, items[1])
        
        // 15 seconds later we should see the last element
        await clock.advance(by: .seconds(15))
        XCTAssertEqual(viewModel.currentCard, items[4])
        
        // 10 seconds later it should go back to the 2nd element
        await clock.advance(by: .seconds(10))
        XCTAssertEqual(viewModel.currentCard, items[1])
        
        // After we stop the carousel, it should still show the 2nd element
        viewModel.stop()
        await clock.advance(by: .seconds(15))
        XCTAssertEqual(viewModel.currentCard, items[1])
        await clock.advance(by: .seconds(5))
        XCTAssertEqual(viewModel.currentCard, items[1])
        
        // After resuming the carousel it should show the same element as before
        viewModel.start()
        
        XCTAssertEqual(viewModel.currentCard, items[1])
        await clock.advance(by: .seconds(6.5))
        XCTAssertEqual(viewModel.currentCard, items[2])
    }
}

// And run the tests
OnboardingViewModelTestCase.defaultTestSuite.run()

class FeatureViewModel: ObservableObject {
    @Published var isButtonDisabled = true
    @Published var showTopView = false
    private let clock: any Clock<Duration>
    
    init(clock: any Clock<Duration>) {
        self.clock = clock
    }
    
    @Sendable func onViewAppear() async {
        do {
            try await clock.sleep(for: .seconds(3))
            isButtonDisabled = false
        } catch { print(error) }
    }
}

// Here we have a view that has a button that is disabled
// for the first 3 seconds. Maybe we want to show the user
// a short video before allowing them to click the button.
struct FeatureView: View {
    @ObservedObject var viewModel: FeatureViewModel
    
    var body: some View {
        VStack {
            if viewModel.showTopView {
                Image(systemName: "car")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            }
            
            Spacer()
            Button {
                viewModel.showTopView.toggle()
            } label: {
                Text(viewModel.showTopView ? "Hide" : "Show")
            }
            .disabled(viewModel.isButtonDisabled)
        }
        .padding(40)
        .task(viewModel.onViewAppear)
    }
}

// If we want to quickly iterate on the design of this view with previews,
// using a ContinuousClock() we would have to wait 3 seconds before
// being able to click the button. To solve this issue we can use
// ImmediateClocks. This type of clock "removes" all delays when sleeping tasks.
// This can also be use in unit testing but TestClock is more useful.
PlaygroundPage.current.setLiveView(
    FeatureView(
        viewModel: FeatureViewModel(clock: ImmediateClock())
//        viewModel: FeatureViewModel(clock: ContinuousClock())
    )
    .frame(width: 200, height: 200)
)

//: [Next](@next)

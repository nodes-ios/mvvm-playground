//: [Previous](@previous)

import Foundation
import PlaygroundSupport
import SwiftUI
import XCTest

/*:
The purpose of the ViewModel is to have all data and logic in one place with well defined interfaces and dependencies
The advantages include but are not limited to:
    * We can prove in unit tests that our logic is consistent with business requirements
    * If a bug is discovered in manual testing it is often trivial to write a test catching the bug and using it for TDD
    * If the view does not contain business logic it will merely be a visual expresssion of state thereby lowering the risk of logic bugs, minimizing the need for manual QA
    *
*/

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    
    ///  A computed property that relies on @Published properties is itself @Published
    var isButtonEnabled: Bool {
        email.contains("@")
        && email.contains(".")
        && email.count >= 6
        && password.count >= 8
    }
    
    /// Function exposed to the view for user interaction
    func loginTapped() {
        // Make login API call
    }
}

// MARK: - Simple unit tests of button enabled state
class BasicTestCase: XCTestCase {
    func testHappyPath() {
        let vm = LoginViewModel()
        vm.email = "j@j.dk"
        XCTAssertFalse(vm.isButtonEnabled)
        vm.password = "12345678"
        XCTAssertTrue(vm.isButtonEnabled)
    }
}

BasicTestCase.defaultTestSuite.run()

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    var body: some View {
        VStack {
            TextField("", text: $viewModel.email)
                .textFieldStyle(.roundedBorder)
            TextField("", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
            Spacer()
               
            Button("Login", action: viewModel.loginTapped)
                .foregroundColor(viewModel.isButtonEnabled ? .black : .gray)
                .buttonStyle(.bordered)
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    LoginView(viewModel: .init())
        .frame(width: 385, height: 667)
)

//: [Next](@next)

//: [Previous](@previous)

import Combine
import Foundation
import PlaygroundSupport
import SwiftUI
import XCTest

// A really easy way to define dependencies is modellng them as simple structs with functions saved in variables. That way they can be replaced inline as needed for mocking or testing, as opposed to using protocols where you need a new conformance every time you need a specific behaviour from you dependency

/// Here we define the interface
struct APIClient {
    struct LoginRequest {
        let email: String
        let password: String
    }
    var login: (LoginRequest) -> AnyPublisher<Void, Error>
}

// Create different behaviours using instances
extension APIClient {
    static let happyMock = APIClient { _ in Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
    static let unhappyMock = APIClient { _ in Fail(error: NSError(domain: "dk.monstar-lab.mvvm", code: 403, userInfo: nil)).eraseToAnyPublisher() }
    static func live(baseURL: URL) -> Self {
        fatalError("Not implemented, make real URLSession thingy here")
    }
}


class LoginViewModel: ObservableObject {
    
    let apiClient: APIClient
    var cancellables: Set<AnyCancellable> = []
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isAPICallInFlight: Bool = false
    
    @Published var error: String?
    @Published var loginSuccessMessage: String?
    
    var isButtonEnabled: Bool {
        email.contains(".") && email.count >= 6 && password.count >= 8 && !isAPICallInFlight
    }
    
    init(
        apiClient: APIClient
    ) {
        self.apiClient = apiClient
    }
    
    func loginTapped() {
        guard !isAPICallInFlight else { return }
        isAPICallInFlight = true
        apiClient.login(.init(email: email, password: password))
            .sink(
                receiveCompletion: { [weak self] in
                    if case .failure = $0 {
                        self?.error = "Something bas happened"
                    }
                    self?.isAPICallInFlight = false
                }, receiveValue: { [weak self] in
                    self?.loginSuccessMessage = "Hooray!"
                }
            ).store(in: &cancellables)
    }
    
    // You may want to intercept what is being written
    func emailChanged(_ email: String) {
        self.email = String(email.prefix(25))// Limit email to 25 char, just for demonstration
    }

    func passwordChanged(_ password: String) {
        self.password = password
    }
}


// MARK: Tests
class BasicDependenciesTestCase: XCTestCase {
    var apiClient = APIClient.happyMock
    var receivedEmails: [String] = []
    var receivedPasswords: [String] = []
    let expectedEmail = "j@j.dk"
    let expectedPassword = "12345678"

    func testHappyPath() {

        // Replace endpoints inline to monitor how they are called
        apiClient.login = { [weak self] request in
            self?.receivedEmails.append(request.email)
            self?.receivedPasswords.append(request.password)
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        let vm = LoginViewModel(apiClient: apiClient)
        vm.email = expectedEmail
        XCTAssertFalse(vm.isButtonEnabled)
        vm.password = expectedPassword
        XCTAssertTrue(vm.isButtonEnabled)
        XCTAssertTrue(vm.email == expectedEmail)
        XCTAssertTrue(vm.password == expectedPassword)
    }
}

BasicDependenciesTestCase.defaultTestSuite.run()

// MARK: - SwiftUI
struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    var body: some View {
        VStack {
            TextField(
                "",
                text: Binding(
                    get: { viewModel.email },
                    set: viewModel.emailChanged
                )
            )
                .textFieldStyle(.roundedBorder)
            if viewModel.isAPICallInFlight {
                ProgressView().progressViewStyle(.circular)
            }
            TextField("", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
            Spacer()
               
            Button("Login", action: viewModel.loginTapped)
                .foregroundColor(viewModel.isButtonEnabled ? .black : .gray)
                .buttonStyle(.bordered)
            viewModel.loginSuccessMessage.map{ Text("Success: \($0)") }
            viewModel.error.map{ Text("Error: \($0)") }
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    LoginView(viewModel: .init(apiClient: .happyMock))
        .frame(width: 385, height: 667)
)

//: [Next](@next)

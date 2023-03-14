//: [Previous](@previous)

import Combine
import CombineSchedulers
import Dependencies
import Foundation
import PlaygroundSupport
import SwiftUI
import XCTest

public struct APIError: Error {
    public let message: String
    public let code: Int
}
/// Here we define the interface
struct APIClient {
    struct LoginRequest {
        let email: String
        let password: String
    }
    /// Login endpoint returns a token
    var login: (LoginRequest) -> AnyPublisher<String, APIError>
}

// Create different behaviours using instances
extension APIClient {
    static let happyMock = APIClient { _ in Just("MockToken").setFailureType(to: APIError.self).eraseToAnyPublisher() }

    static let unhappyMock = APIClient { _ in Fail(
        error: APIError(
            message: "ErrorText",
            code: 403
        )
    ).eraseToAnyPublisher() }
    
    /// create an APIClient that will evoke an XCTFail for all endpoints if called, cmd
    static let failing = APIClient { _ in .failing("\(Self.self).login is not implemented") }
    
    static let live = APIClient { _ in Just("MockToken").setFailureType(to: APIError.self).eraseToAnyPublisher() }
}

private enum APIClientKey: DependencyKey {
  static let liveValue = APIClient.live
}

extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClientKey.self] }
    set { self[APIClientKey.self] = newValue }
  }
}

class LoginViewModel: ObservableObject {
    
    @Dependency(\.apiClient) var apiClient: APIClient
    @Dependency(\.mainQueue) var mainQueue: AnySchedulerOf<DispatchQueue>
    
    var cancellables: Set<AnyCancellable> = []
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isAPICallInFlight: Bool = false
    
    @Published var error: String?
    @Published var loginSuccessMessage: String?
    var token: String?
    
    var isButtonEnabled: Bool {
        email.contains(".") && email.count >= 6 && password.count >= 8 && !isAPICallInFlight
    }
    
    init() {}
    
    func loginTapped() {
        guard !isAPICallInFlight else { return }
        isAPICallInFlight = true
        apiClient.login(.init(email: email, password: password))
            .receive(on: mainQueue)
            .sink(
                receiveCompletion: { [weak self] in
                    if case .failure(let error) = $0  {
                        self?.error = error.message
                    }
                    self?.isAPICallInFlight = false
                }, receiveValue: { [weak self] token in
                    self?.token = token
                    self?.loginSuccessMessage = "Hooray!"
                }
            )
            .store(in: &cancellables)
    }
    
    // You may want to intercept what is being written
    func emailChanged(_ email: String) {
        self.email = String(email.prefix(25))// Limit email to 25 char, just for demonstration
    }

    func passwordChanged(_ password: String) {
        self.password = password
    }
}


// MARK: - Tests -
class AdvancedDependenciesTestCase: XCTestCase {

    /// Default to an environment that fails on all dependencies to make sure we don't use dependencies we didn't expect
   
    var receivedEmails: [String] = []
    var receivedPasswords: [String] = []
    let expectedEmail = "j@j.dk"
    let expectedPassword = "12345678"

    override func setUp() {
        receivedEmails.removeAll()
        receivedPasswords.removeAll()
    }

    func testHappyPath() {
        
        let scheduler = DispatchQueue.test
        
        let vm = withDependencies {
            $0.mainQueue = scheduler.eraseToAnyScheduler()
            $0.apiClient = .happyMock
//            Replace endpoints inline to monitor how they are called
            $0.apiClient.login = { [weak self] request in
                self?.receivedEmails.append(request.email)
                self?.receivedPasswords.append(request.password)
                return Just("TheToken").setFailureType(to: APIError.self).eraseToAnyPublisher()
            }
        } operation: {
            LoginViewModel()
        }

        vm.emailChanged(expectedEmail)
        XCTAssertFalse(vm.isAPICallInFlight)
        XCTAssertFalse(vm.isButtonEnabled)

        vm.passwordChanged(expectedPassword)
        XCTAssertTrue(vm.isButtonEnabled)
        vm.loginTapped()

        /// Make sure vm is now in 'make-api-call' state
        XCTAssertFalse(vm.isButtonEnabled)
        XCTAssertTrue(vm.isAPICallInFlight)
        /// User taps twice by accident
        vm.loginTapped()
        /// The main queue advances by one runloop. Because we receive on the mainQueue this will make the apicall complete
        scheduler.advance()

        /// Make sure api is only called once with correct email even though user tapped twice
        XCTAssert(receivedEmails == [expectedEmail])
        /// Make sure correct password is sent
        XCTAssert(receivedPasswords == [expectedPassword])
        /// Login was successful
        XCTAssert(vm.loginSuccessMessage == "Hooray!")
        XCTAssert(vm.token == "TheToken")
        XCTAssertNil(vm.error)
    }

    func testUnhappyPath() {
        
        let scheduler = DispatchQueue.test
        
        let vm = withDependencies {
            $0.mainQueue = scheduler.eraseToAnyScheduler()
            $0.apiClient = .happyMock
//            Replace endpoints inline to monitor how they are called
            $0.apiClient.login = { [weak self] request in
                self?.receivedEmails.append(request.email)
                self?.receivedPasswords.append(request.password)
                return Fail(
                    error: APIError(
                        message: "ErrorText",
                        code: 403
                    )
                ).eraseToAnyPublisher()
            }
        } operation: {
            LoginViewModel()
        }

        vm.emailChanged(expectedEmail)
        XCTAssertFalse(vm.isButtonEnabled)
        vm.passwordChanged(expectedPassword)
        XCTAssertTrue(vm.isButtonEnabled)
        vm.loginTapped()
        /// Make sure vm is now in 'make-api-call' state
        XCTAssertFalse(vm.isButtonEnabled)
        XCTAssertTrue(vm.isAPICallInFlight)

        /// The main queue advances by one runloop. Because we receive on the mainQueue this will make the apicall complete
        scheduler.advance()

        /// Make sure api is only called once with correct email even though user tapped twice
        XCTAssert(receivedEmails == [expectedEmail])
        /// Make sure correct password is sent
        XCTAssert(receivedPasswords == [expectedPassword])
        /// Login failed
        XCTAssert(vm.error == "ErrorText")
        XCTAssertNil(vm.token)
    }
}

// And run the tests
AdvancedDependenciesTestCase.defaultTestSuite.run()

// Mark: - SwiftUI View
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
    LoginView(
        viewModel: .init()
    )
    .frame(width: 385, height: 667)
)

//: [Next](@next)




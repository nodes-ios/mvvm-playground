//: [Previous](@previous)

import Clocks
import Combine
import Foundation
import PlaygroundSupport
import SwiftUI
import XCTest
import XCTestDynamicOverlay

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
}

struct LoginEnvironment {
    var clock: any Clock<Duration>
    var apiClient: APIClient
}

extension LoginEnvironment {
    
    static let mock = Self(
        clock: ContinuousClock(),
        apiClient: .happyMock
    )
    
//    static let failing = Self(
//        clock: { fatalError() }(),
//        apiClient: .failing
//    )

//    static let unhappyMock = Self(
//        mainQueue: .main.eraseToAnyScheduler(),
//        apiClient: .unhappyMock
//    )
}

class LoginViewModel: ObservableObject {
    
    let environment: LoginEnvironment
    var cancellables: Set<AnyCancellable> = []
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isAPICallInFlight: Bool = false
    
    @Published var error: String?
    @Published var loginSuccessMessage: String?
    @Published var helloMessage: String?
    
    var token: String?
    
    var isButtonEnabled: Bool {
        email.contains(".") && email.count >= 6 && password.count >= 8 && !isAPICallInFlight
    }
    
    init(
        environment: LoginEnvironment
    ) {
        self.environment = environment
    }
    
    func onAppear() async {
        do {
            try await environment.clock.sleep(for: .seconds(3))
            helloMessage = "Hello"
        } catch {}
    }
    
    func loginTapped() {
//        guard !isAPICallInFlight else { return }
//        isAPICallInFlight = true
//        environment.apiClient.login(.init(email: email, password: password))
//            .receive(on: environment.mainQueue)
//            .sink(
//                receiveCompletion: { [weak self] in
//                    if case .failure(let error) = $0  {
//                        self?.error = error.message
//                    }
//                    self?.isAPICallInFlight = false
//                }, receiveValue: { [weak self] token in
//                    self?.token = token
//                    self?.loginSuccessMessage = "Hooray!"
//                }
//            )
//            .store(in: &cancellables)
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
    lazy var enviroment = LoginEnvironment(clock: clock, apiClient: .failing)
    let clock = ImmediateClock()
    var receivedEmails: [String] = []
    var receivedPasswords: [String] = []
    let expectedEmail = "j@j.dk"
    let expectedPassword = "12345678"

    override func setUp() {
        receivedEmails.removeAll()
        receivedPasswords.removeAll()
//        let enviroment = LoginEnvironment(clock: clock, apiClient: .failing)
        /// Use a Test Scheduler to control the passing of runloops and time on the mainQueue
//        enviroment.clock = clock
    }

    
    func testHappyPath() async {
        let vm = LoginViewModel(environment: enviroment)
        XCTAssertNil(vm.helloMessage)
        Task {
            await vm.onAppear()
        }
        XCTAssertEqual("Hello", vm.helloMessage)
//        await clock.advance(by: .seconds(2))
//        XCTAssertNil(vm.helloMessage)
//
//        await clock.advance(by: .seconds(1))
//        XCTAssertEqual("Hello", vm.helloMessage)
//        await clock.run()
//        XCTAssertEqual("Hello", vm.helloMessage)
    }
//    func testHappyPath() async {
//        let vm = LoginViewModel(environment: enviroment)
//        XCTAssertNil(vm.helloMessage)
//        Task {
//            await vm.onAppear()
//        }
//        Task {
//            await vm.onAppear()
//        }
//        XCTAssertNil(vm.helloMessage)
//        await clock.advance(by: .seconds(2))
//        XCTAssertNil(vm.helloMessage)
//
//        await clock.advance(by: .seconds(1))
//        XCTAssertEqual("Hello", vm.helloMessage)
//        await clock.run()
//        XCTAssertEqual("Hello", vm.helloMessage)
//    }

    func testUnhappyPath() {
//        enviroment.apiClient.login = { [weak self] request in
//            self?.receivedEmails.append(request.email)
//            self?.receivedPasswords.append(request.password)
//            return Fail(
//                error: APIError(
//                    message: "ErrorText",
//                    code: 403
//                )
//            ).eraseToAnyPublisher()
//        }
//
//        let vm = LoginViewModel(environment: enviroment)
//        vm.emailChanged(expectedEmail)
//        XCTAssertFalse(vm.isButtonEnabled)
//        vm.passwordChanged(expectedPassword)
//        XCTAssertTrue(vm.isButtonEnabled)
//        vm.loginTapped()
//        /// Make sure vm is now in 'make-api-call' state
//        XCTAssertFalse(vm.isButtonEnabled)
//        XCTAssertTrue(vm.isAPICallInFlight)
//
//        /// The main queue advances by one runloop. Because we receive on the mainQueue this will make the apicall complete
//        scheduler.advance()
//
//        /// Make sure api is only called once with correct email even though user tapped twice
//        XCTAssert(receivedEmails == [expectedEmail])
//        /// Make sure correct password is sent
//        XCTAssert(receivedPasswords == [expectedPassword])
//        /// Login failed
//        XCTAssert(vm.error == "ErrorText")
//        XCTAssertNil(vm.token)
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
            if let message = viewModel.helloMessage {
                Text(message)
                    .font(.largeTitle)
            }
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
        .task {
            await viewModel.onAppear()
        }
    }
}

PlaygroundPage.current.setLiveView(
    LoginView(
        viewModel: .init(environment: .mock)
    )
    .frame(width: 385, height: 667)
)

//: [Next](@next)



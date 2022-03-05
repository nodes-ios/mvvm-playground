//: [Previous](@previous)

import Combine
import CombineSchedulers
import Foundation
import PlaygroundSupport
import SwiftUI

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
    static let unhappyMock = APIClient { _ in Fail(error: APIError(
        message: "ErrorText",
        code: 403)
    ).eraseToAnyPublisher() }
    
    /// create an APIClient that will evoke an XCTFail for all endpoints if called, cmd
    static let failing = APIClient { _ in .failing("\(Self.self).login is not implemented") }
}


struct LoginEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue>
    var apiClient: APIClient
}

extension LoginEnvironment {
    
    static let mock = Self(
        mainQueue: .main.eraseToAnyScheduler(),
        apiClient: .happyMock
    )
    
    static let failing = Self(
        mainQueue: .failing("\(Self.self).mainQueue is not implemented"),
        apiClient: .failing
    )
}


class LoginViewModel: ObservableObject {
    
    let environment: LoginEnvironment
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
    
    init(
        environment: LoginEnvironment
    ) {
        self.environment = environment
    }
    
    func loginTapped() {
        guard !isAPICallInFlight else { return }
        isAPICallInFlight = true
        environment.apiClient.login(.init(email: email, password: password))
            .receive(on: environment.mainQueue)
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


// MARK: - Tests -

/// Test happy path

do {
    /// Default to an environment that fails on all dependencies to make sure we don't use dependencies we didn't expect
    var enviroment = LoginEnvironment.failing
    
    /// Use a Test Scheduler to control the passing of runloops and time on the mainQueue
    let scheduler = DispatchQueue.test
    enviroment.mainQueue = scheduler.eraseToAnyScheduler()
    
    /// Properties to save data sent to the 'api' in
    var receivedEmails: [String] = []
    var receivedPasswords: [String] = []
    
    /// Replace endpoints inline to monitor how they are called
    enviroment.apiClient.login = { request in
        receivedEmails.append(request.email)
        receivedPasswords.append(request.password)
        return Just("TheToken").setFailureType(to: APIError.self).eraseToAnyPublisher()
    }
    
    let vm = LoginViewModel(environment: enviroment)
    vm.emailChanged("j@j.dk")
    assert(!vm.isButtonEnabled)
    vm.passwordChanged("12345678")
    assert(vm.isButtonEnabled)
    vm.loginTapped()
    
    /// Make sure vm is now in 'make-api-call' state
    assert(vm.isButtonEnabled == false)
    assert(vm.isAPICallInFlight)
    /// User taps twice by accident
    vm.loginTapped()
    /// The main queue advances by one runloop. Because we receive on the mainQueue this will make the apicall complete
    scheduler.advance()
    
    /// Make sure api is only called once with correct email even though user tapped twice
    assert(receivedEmails == ["j@j.dk"])
    /// Make sure correct password is sent
    assert(receivedPasswords == ["12345678"])
    /// Login was successful
    assert(vm.loginSuccessMessage == "Hooray!")
    assert(vm.token == "TheToken")
    assert(vm.error == nil)
}


/// Test unhappy path
///
/// Default to an environment that fails on all dependencies to make sure we don't use dependencies we didn't expect
var enviroment = LoginEnvironment.failing

/// Use a Test Scheduler to control the passing of runloops and time on the mainQueue
let scheduler = DispatchQueue.test
enviroment.mainQueue = scheduler.eraseToAnyScheduler()

/// Properties to save data sent to the 'api' in
var receivedEmails: [String] = []
var receivedPasswords: [String] = []

/// Replace endpoints inline to monitor how they are called
enviroment.apiClient.login = { request in
    receivedEmails.append(request.email)
    receivedPasswords.append(request.password)
    return Fail(
        error: APIError(
            message: "ErrorText",
            code: 403
        )
    ).eraseToAnyPublisher()
}

let vm = LoginViewModel(environment: enviroment)
vm.emailChanged("j@j.dk")
assert(!vm.isButtonEnabled)
vm.passwordChanged("12345678")
assert(vm.isButtonEnabled)
vm.loginTapped()
/// Make sure vm is now in 'make-api-call' state
assert(vm.isButtonEnabled == false)
assert(vm.isAPICallInFlight)

/// The main queue advances by one runloop. Because we receive on the mainQueue this will make the apicall complete
scheduler.advance()

/// Make sure api is only called once with correct email even though user tapped twice
assert(receivedEmails == ["j@j.dk"])
/// Make sure correct password is sent
assert(receivedPasswords == ["12345678"])
/// Login failed
assert(vm.error == "ErrorText")
assert(vm.token == nil)

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
               
        }
        .padding()
    }
}

//
//PlaygroundPage.current.setLiveView(
//    LoginView(viewModel: .init(environment: .mock))
//        .frame(width: 385, height: 667)
//)



//: [Next](@next)



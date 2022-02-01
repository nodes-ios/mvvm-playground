//: [Previous](@previous)

import Combine
import CombineSchedulers
import Foundation
import PlaygroundSupport
import SwiftUI
import XCTestDynamicOverlay

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
        apiClient.login(.init(email: email, password: password))
            .receive(on: environment.mainQueue)
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

var apiClient = APIClient.happyMock

var receivedEmails: [String] = []
var receivedPasswords: [String] = []

// Replace endpoints inline to monitor how they are called
apiClient.login = { request in
    receivedEmails.append(request.email)
    receivedPasswords.append(request.password)
    return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
}

var enviroment = LoginEnvironment.failing

let vm = LoginViewModel(environment: enviroment)
vm.emailChanged("j@j.dk")
assert(!vm.isButtonEnabled)
vm.passwordChanged("12345678")
assert(vm.isButtonEnabled)
vm.loginTapped()
vm.loginTapped() // User taps twice
assert(vm.loginSuccessMessage == "Hooray!") // Login was successful
assert(vm.error == nil)

assert(receivedEmails.count == 1) // Due to synchronous api this fails right now


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


PlaygroundPage.current.setLiveView(
    LoginView(viewModel: .init(environment: .mock))
        .frame(width: 385, height: 667)
)



//: [Next](@next)



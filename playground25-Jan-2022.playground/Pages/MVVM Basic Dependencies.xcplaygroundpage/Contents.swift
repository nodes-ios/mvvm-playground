//: [Previous](@previous)

import Combine
import Foundation
import PlaygroundSupport
import SwiftUI

// Make interface
struct APIClient {
    var _login: (String, String) -> AnyPublisher<Void, Error>
    
    // This is just convenience for getting named arguments
    func login(email: String, password: String) -> AnyPublisher<Void, Error> { _login(email, password) }
}

// Create different behaviours
extension APIClient {
    static let happyMock = APIClient { _, _ in Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
    static let unhappyMock = APIClient { _, _ in Fail(error: NSError(domain: "dk.monstar-lab.mvvm", code: 403, userInfo: nil)).eraseToAnyPublisher() }
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
        apiClient.login(email: email, password: password)
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
apiClient._login = { email, password in
    receivedEmails.append(email)
    receivedPasswords.append(password)
    return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
}

let vm = LoginViewModel(apiClient: apiClient)
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
            TextField("", text: Binding(get: { viewModel.email }, set: viewModel.emailChanged))
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
    LoginView(viewModel: .init(apiClient: .happyMock))
        .frame(width: 385, height: 667)
)



//: [Next](@next)



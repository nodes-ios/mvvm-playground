import Foundation
import Combine
import CombineSchedulers
import SwiftUI

public struct APIClient {
    public init(login: @escaping (APIClient.LoginRequest) -> AnyPublisher<Void, Error>) {
        self.login = login
    }
    
    public struct LoginRequest {
        public let email: String
        public let password: String
    }
    public var login: (LoginRequest) -> AnyPublisher<Void, Error>
}

// Create different behaviours using instances
extension APIClient {
    static let happyMock = APIClient { _ in Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
    static let unhappyMock = APIClient { _ in Fail(error: NSError(domain: "dk.monstar-lab.mvvm", code: 403, userInfo: nil)).eraseToAnyPublisher() }
    
    static let failing = APIClient { _ in .failing("\(Self.self).login is not implemented") }
}


public struct LoginEnvironment {
    
    public var mainQueue: AnySchedulerOf<DispatchQueue>
    public var apiClient: APIClient
    
    public init(mainQueue: AnySchedulerOf<DispatchQueue>, apiClient: APIClient) {
        self.mainQueue = mainQueue
        self.apiClient = apiClient
    }
}

public extension LoginEnvironment {
    
    static let mock = Self(
        mainQueue: .main.eraseToAnyScheduler(),
        apiClient: .happyMock
    )
    
    static let failing = Self(
        mainQueue: .failing("\(Self.self).mainQueue is not implemented"),
        apiClient: .failing
    )
}


public class LoginViewModel: ObservableObject {
    
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
    
    public init(
        environment: LoginEnvironment
    ) {
        self.environment = environment
    }
    
    func onAppear() {
        
    }
    
    func loginTapped() {
        guard !isAPICallInFlight else { return }
        isAPICallInFlight = true
        environment.apiClient.login(.init(email: email, password: password))
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


public struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    
    public init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
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

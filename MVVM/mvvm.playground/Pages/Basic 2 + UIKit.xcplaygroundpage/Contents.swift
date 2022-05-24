//: [Previous](@previous)

import Combine
import Foundation
import PlaygroundSupport
import SwiftUI
import XCTest

/// Sometimes you may want to intercept what is being written to the property. To do this you can make a custom Binding in the SwiftUI view that calls a set function on the ViewModel.
/// The same ViewModel can be used in UIKit. At the bottom there's UIViewController using the ViewModel
class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    
    var isButtonEnabled: Bool {
        email.contains(".") && email.count >= 6 && password.count >= 8
    }
    
    func loginTapped() {
        // Make login API call
    }
    
    func emailChanged(_ email: String) {
        self.email = email
    }

    func passwordChanged(_ password: String) {
        self.password = String(password.prefix(9)) // Limit email to 9 char, just for demonstration
    }
}

// MARK: Tests
class BasicUIKitTestCase: XCTestCase {
    func testHappyPath() {
        let expectedEmail = "j@j.dk"
        let expectedPassword = "12345678"

        let vm = LoginViewModel()
        vm.email = expectedEmail
        XCTAssertFalse(vm.isButtonEnabled)
        vm.password = expectedPassword
        XCTAssertTrue(vm.isButtonEnabled)
        XCTAssertTrue(vm.email == expectedEmail)
        XCTAssertTrue(vm.password == expectedPassword)

        vm.passwordChanged("123456789123456789") // Test that inputting too long password clamps it to 9 chars
        XCTAssertTrue(vm.password == "123456789")

    }
}

BasicUIKitTestCase.defaultTestSuite.run()

/// SwiftUI version
struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    var body: some View {
        VStack {
            TextField(
                "",
                text: Binding( // Create a custom binding to be able to pass data through a function on the VM
                    get: { viewModel.email },
                    set: viewModel.emailChanged
                )
            )
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

/// UIKit version
class LoginViewController: UIViewController, UITextFieldDelegate {
    
    enum FieldTag: Int {
        case email
        case password
    }
    
    let viewModel: LoginViewModel
    
    var cancelleables: Set<AnyCancellable> = []
    
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView()
        self.view = view
        view.backgroundColor = .lightGray
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),]
        )
        let emailField = UITextField()
        emailField.translatesAutoresizingMaskIntoConstraints = false
        emailField.font = .systemFont(ofSize: 24)
        emailField.tag = FieldTag.email.rawValue
        emailField.delegate = self
        emailField.backgroundColor = .white
        emailField.layer.borderColor = UIColor.black.cgColor
        emailField.layer.borderWidth = 1
        // Here we observe the email
        viewModel.$email.sink { emailField.text = $0 }
        .store(in: &cancelleables)
        stack.addArrangedSubview(emailField)
        
        let passwordField = UITextField()
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.font = .systemFont(ofSize: 24)
        passwordField.tag = FieldTag.password.rawValue
        passwordField.delegate = self
        passwordField.backgroundColor = .white
        passwordField.layer.borderColor = UIColor.black.cgColor
        passwordField.layer.borderWidth = 1
        // Here we observe the password
        viewModel.$password.sink { passwordField.text = $0 }
        .store(in: &cancelleables)
        stack.addArrangedSubview(passwordField)
        
        let button = UIButton.init(primaryAction: .init(title: "Login", handler: { [viewModel] _ in
            viewModel.loginTapped()
        }))
        button.backgroundColor = .red
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        
        // Here we have to cheat as the computed property isButtonEnabled doesn't seem to expose a publisher as such, so we use textfields as trigger
        viewModel.$email.zip(viewModel.$password).sink { [viewModel] _, _ in
            button.isEnabled = viewModel.isButtonEnabled
        }
        .store(in: &cancelleables)
        stack.addArrangedSubview(button)
        
    }
    
    // As we want to always control what is written in the textfield from the viewmodel we always return false here
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return false }
        let result = (text as NSString).replacingCharacters(in: range, with: string)
        switch FieldTag(rawValue: textField.tag)! {
            case .email: viewModel.emailChanged(result)
            case .password: viewModel.passwordChanged(result)
        }
        
        return false
    }
}


//PlaygroundPage.current.setLiveView(
//    LoginView(viewModel: .init())
//        .frame(width: 385, height: 667)
//)

PlaygroundPage.current.setLiveView(
    ToSwiftUI {
        LoginViewController(viewModel: .init())
    }
        .frame(width: 385, height: 667)
)




//: [Next](@next)



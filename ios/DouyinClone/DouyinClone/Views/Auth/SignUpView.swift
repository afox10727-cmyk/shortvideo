import SwiftUI

struct SignUpView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Display name
            HStack {
                Image(systemName: "person.fill")
                    .foregroundStyle(.gray)
                TextField("昵称", text: Bindable(authViewModel).signUpDisplayName)
                    .textContentType(.name)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Username
            HStack {
                Image(systemName: "at")
                    .foregroundStyle(.gray)
                TextField("用户名（唯一）", text: Bindable(authViewModel).signUpUsername)
                    .autocapitalization(.none)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Email
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(.gray)
                TextField("邮箱", text: Bindable(authViewModel).signUpEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Password
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.gray)
                SecureField("密码（至少6位）", text: Bindable(authViewModel).signUpPassword)
                    .textContentType(.newPassword)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Error message
            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            // Sign up button
            Button {
                Task { await authViewModel.signUp() }
            } label: {
                Text("注册")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.pink, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(authViewModel.isLoading)
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    SignUpView()
        .environment(AuthViewModel())
}

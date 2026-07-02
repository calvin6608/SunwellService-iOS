import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: AuthSession

    @State private var username = ""
    @State private var password = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Image("LoginLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 260)
                        .padding(.top, 32)

                    VStack(spacing: 6) {
                        Text("Sunwell Service App")
                            .font(.title2.weight(.semibold))
                        Text("iOS starter")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 14) {
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .sunwellField()

                        SecureField("Password", text: $password)
                            .sunwellField()

                        Button {
                            Task {
                                await session.login(username: username, password: password)
                                if session.isLoggedIn {
                                    password = ""
                                }
                            }
                        } label: {
                            HStack {
                                if session.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                Text(session.isLoading ? "Logging in..." : "Login")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(session.isLoading)
                    }

                    if !session.errorMessage.isEmpty {
                        Text(session.errorMessage)
                            .font(.callout)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Sunwell")
        }
        .onAppear {
            username = session.loadSavedUsername()
        }
    }
}




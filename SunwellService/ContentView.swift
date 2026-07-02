import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: AuthSession

    var body: some View {
        Group {
            if session.isLoggedIn {
                HomeView()
            } else {
                LoginView()
            }
        }
        .accentColor(.sunwellBlue)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthSession())
    }
}




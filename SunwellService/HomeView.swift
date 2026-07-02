import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: AuthSession

    var body: some View {
        NavigationView {
            List {
                Section("主要查詢") {
                    NavigationLink("01 訂單資料查詢", destination: OrderSearchView())
                    NavigationLink("02 零件 / BOM 查詢", destination: PartSearchView())
                    NavigationLink("CAD Drawing", destination: DrawingSearchView())
                    NavigationLink("Service Records", destination: ServiceRecordSearchView())
                }

                Section("Next Porting Targets") {
                    Label("Machine BOM", systemImage: "wrench.and.screwdriver")
                    Label("Remote Service", systemImage: "person.text.rectangle")
                    Label("Commissioning", systemImage: "checklist")
                    Label("Tools", systemImage: "folder")
                }
                .foregroundColor(.secondary)
            }
            .navigationTitle("Sunwell")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(session.username.isEmpty ? "User" : session.username)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        session.logout()
                    }
                }
            }
        }
    }
}







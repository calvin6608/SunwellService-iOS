import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: AuthSession

    var body: some View {
        NavigationStack {
            List {
                Section("Main Query") {
                    NavigationLink("Order", destination: OrderSearchView())
                    NavigationLink("Part/BOM", destination: PartSearchView())
                    NavigationLink("CAD Drawing", destination: DrawingSearchView())
                    NavigationLink("Service Records", destination: ServiceRecordSearchView())
                }

                Section("Next Porting Targets") {
                    Label("Machine BOM", systemImage: "wrench.and.screwdriver")
                    Label("Remote Service", systemImage: "person.text.rectangle")
                    Label("Commissioning", systemImage: "checklist")
                    Label("Tools", systemImage: "folder")
                }
                .foregroundStyle(.secondary)
            }
            .navigationTitle("Sunwell")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(session.username.isEmpty ? "User" : session.username)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
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



import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: AuthSession

    var body: some View {
        NavigationView {
            List {
                Section("主要查詢") {
                    NavigationLink("01 訂單資料查詢", destination: OrderSearchView())
                    NavigationLink("02 零件 / BOM 查詢", destination: PartSearchView())
                    NavigationLink("03 資料查詢", destination: DataSearchView())
                    NavigationLink("99 ERP", destination: ErpSearchView())
                    NavigationLink("09 MCS/MT 次組立", destination: MachineBomView())
                    NavigationLink("10 工具", destination: ToolsView())
                    NavigationLink("07 CAD 圖檔查詢", destination: DrawingSearchView())
                    NavigationLink("Service Records", destination: ServiceRecordSearchView())
                }

                Section("Next Porting Targets") {
                    Label("Remote Service", systemImage: "person.text.rectangle")
                    Label("Commissioning", systemImage: "checklist")
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




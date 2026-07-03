import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: AuthSession

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let background = Color(red: 0.07, green: 0.14, blue: 0.13)
    private let panelAlt = Color(red: 0.14, green: 0.30, blue: 0.42)
    private let accent = Color(red: 0.28, green: 0.87, blue: 0.81)
    private let textColor = Color(red: 0.86, green: 0.96, blue: 0.94)

    var body: some View {
        NavigationView {
            ZStack {
                background
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        dashboardSection(title: "主要查詢", icon: "magnifyingglass") {
                            LazyVGrid(columns: columns, spacing: 12) {
                                navCard(
                                    index: "01",
                                    title: "訂單資料查詢",
                                    subtitle: "Order",
                                    icon: "doc.text",
                                    destination: OrderSearchView()
                                )
                                navCard(
                                    index: "02",
                                    title: "零件 / BOM 查詢",
                                    subtitle: "Part / BOM",
                                    icon: "cube.box",
                                    destination: PartSearchView()
                                )
                                navCard(
                                    index: "03",
                                    title: "資料查詢",
                                    subtitle: "Data Search",
                                    icon: "tray",
                                    destination: DataSearchView()
                                )
                                navCard(
                                    index: "99",
                                    title: "ERP",
                                    subtitle: "Stock Change",
                                    icon: "building.2",
                                    destination: ErpSearchView()
                                )
                            }
                        }

                        dashboardSection(title: "圖檔 / 機械", icon: "ruler") {
                            LazyVGrid(columns: columns, spacing: 12) {
                                navCard(
                                    index: "07",
                                    title: "CAD 圖檔查詢",
                                    subtitle: "Drawing",
                                    icon: "triangle",
                                    destination: DrawingSearchView()
                                )
                                navCard(
                                    index: "09",
                                    title: "MCS/MT 次組立",
                                    subtitle: "Machine BOM",
                                    icon: "gear",
                                    destination: MachineBomView()
                                )
                            }
                        }

                        dashboardSection(title: "工具 / 紀錄", icon: "folder") {
                            LazyVGrid(columns: columns, spacing: 12) {
                                navCard(
                                    index: "10",
                                    title: "工具",
                                    subtitle: "Tools",
                                    icon: "wrench",
                                    destination: ToolsView()
                                )
                                navCard(
                                    index: "SR",
                                    title: "服務紀錄",
                                    subtitle: "Service Records",
                                    icon: "clock",
                                    destination: ServiceRecordSearchView()
                                )
                            }
                        }

                        dashboardSection(title: "之後移植", icon: "calendar") {
                            LazyVGrid(columns: columns, spacing: 12) {
                                disabledCard(
                                    title: "Remote Service",
                                    subtitle: "待移植",
                                    icon: "person.crop.rectangle"
                                )
                                disabledCard(
                                    title: "Commissioning",
                                    subtitle: "待移植",
                                    icon: "checkmark.square"
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.username.isEmpty ? "User" : session.username)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(red: 0.68, green: 0.78, blue: 0.78))

                    Text("昇威服務系統")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer()

                Button(action: {
                    session.logout()
                }) {
                    Text("登出")
                        .font(.headline)
                        .foregroundColor(textColor)
                        .padding(.horizontal, 20)
                        .frame(height: 52)
                        .background(Color(red: 0.17, green: 0.31, blue: 0.48))
                        .cornerRadius(26)
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "iphone")
                    .foregroundColor(accent)
                Text("iOS port in progress")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(red: 0.76, green: 0.92, blue: 0.89))
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(Color(red: 0.12, green: 0.22, blue: 0.25))
            .cornerRadius(8)
        }
    }

    private func dashboardSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(accent)
                    .frame(width: 28)

                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(textColor)

                Rectangle()
                    .fill(Color(red: 0.18, green: 0.41, blue: 0.52))
                    .frame(height: 1)
                    .padding(.leading, 4)
            }

            content()
        }
    }

    private func navCard<Destination: View>(
        index: String,
        title: String,
        subtitle: String,
        icon: String,
        destination: Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            cardContent(
                index: index,
                title: title,
                subtitle: subtitle,
                icon: icon,
                isEnabled: true
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func disabledCard(
        title: String,
        subtitle: String,
        icon: String
    ) -> some View {
        cardContent(
            index: "",
            title: title,
            subtitle: subtitle,
            icon: icon,
            isEnabled: false
        )
    }

    private func cardContent(
        index: String,
        title: String,
        subtitle: String,
        icon: String,
        isEnabled: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(isEnabled ? accent : Color(red: 0.48, green: 0.56, blue: 0.56))
                    .frame(width: 36, height: 36)

                Spacer()

                if !index.isEmpty {
                    Text(index)
                        .font(.headline.weight(.bold))
                        .foregroundColor(isEnabled ? Color(red: 0.77, green: 0.95, blue: 0.92) : .secondary)
                }
            }

            Spacer(minLength: 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundColor(isEnabled ? textColor : Color(red: 0.58, green: 0.65, blue: 0.65))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isEnabled ? Color(red: 0.69, green: 0.82, blue: 0.82) : Color(red: 0.44, green: 0.52, blue: 0.52))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 136, alignment: .leading)
        .background(isEnabled ? panelAlt : Color(red: 0.10, green: 0.19, blue: 0.19))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isEnabled ? Color(red: 0.18, green: 0.40, blue: 0.48) : Color(red: 0.15, green: 0.27, blue: 0.26), lineWidth: 1)
        )
        .cornerRadius(8)
    }
}


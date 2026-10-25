import SwiftUI

struct RootView: View {
    @State private var selectedTab = AppTab.map
    @State private var isPresentingNewReport = false

    var body: some View {
        TabView(selection: $selectedTab) {
            MapScreen()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(AppTab.map)

            ReportsScreen()
                .tabItem {
                    Label("Reports", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(AppTab.reports)
        }
        .overlay(alignment: .bottom) {
            Button {
                isPresentingNewReport = true
            } label: {
                Label("Report animal", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 48)
                    .background(.tint, in: Capsule())
                    .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
            }
            .padding(.bottom, 52)
            .accessibilityHint("Create a missing pet or animal sighting report")
        }
        .sheet(isPresented: $isPresentingNewReport) {
            NewReportView()
        }
    }
}

private enum AppTab: Hashable {
    case map
    case reports
}

import SwiftUI

struct RootView: View {
    @State private var selectedTab = AppTab.map
    @State private var previousTab = AppTab.map
    @State private var isPresentingNewReport = false
    @State private var publishedMessage: String?
    @State private var toastTask: Task<Void, Never>?

    var body: some View {
        TabView(selection: $selectedTab) {
            MapScreen()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(AppTab.map)

            Color.clear
                .tabItem {
                    Label("Report", systemImage: "plus.circle.fill")
                }
                .tag(AppTab.create)

            ReportsScreen()
                .tabItem {
                    Label("Reports", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(AppTab.reports)
        }
        .tint(Color.petSignalGreen)
        .onChange(of: selectedTab) { oldTab, newTab in
            if newTab == .create {
                isPresentingNewReport = true
                selectedTab = oldTab == .create ? previousTab : oldTab
            } else {
                previousTab = newTab
            }
        }
        .sheet(isPresented: $isPresentingNewReport) {
            NewReportView { _ in
                toastTask?.cancel()
                publishedMessage = "Report published to the community"
                selectedTab = .reports
                toastTask = Task {
                    try? await Task.sleep(for: .seconds(3))
                    guard !Task.isCancelled else { return }
                    publishedMessage = nil
                }
            }
        }
        .overlay(alignment: .top) {
            if let publishedMessage {
                Label(publishedMessage, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color.petSignalGreen, in: Capsule())
                    .shadow(radius: 12, y: 5)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: publishedMessage)
    }
}

private enum AppTab: Hashable {
    case map
    case create
    case reports
}

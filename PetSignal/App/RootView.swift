import SwiftUI
import UIKit

struct RootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedTab = AppTab.map
    @State private var isPresentingNewReport = false
    @State private var publishedMessage: String?
    @State private var toastTask: Task<Void, Never>?

    var body: some View {
        TabView(selection: $selectedTab) {
            MapScreen {
                isPresentingNewReport = true
            }
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(AppTab.map)

            ReportsScreen {
                isPresentingNewReport = true
            }
                .tabItem { Label("Reports", systemImage: "list.bullet.rectangle.portrait") }
                .tag(AppTab.reports)
        }
        .tint(Color.petSignalGreen)
        .sheet(isPresented: $isPresentingNewReport) {
            NewReportView { _ in
                toastTask?.cancel()
                publishedMessage = "Report saved on this device"
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "Report saved on this device"
                )
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
                    .frame(minHeight: 48)
                    .background(Color.petSignalGreen, in: RoundedRectangle(cornerRadius: 8))
                    .padding(.top, 8)
                    .accessibilityAddTraits(.isStaticText)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: publishedMessage)
    }
}

private enum AppTab: Hashable {
    case map
    case reports
}

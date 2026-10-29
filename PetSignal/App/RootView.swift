import SwiftUI
import UIKit

struct RootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedTab = AppTab.map
    @State private var isPresentingNewReport = false
    @State private var savedMessage: String?
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
                .tabItem { Label("Community Feed", systemImage: "rectangle.grid.1x2.fill") }
                .tag(AppTab.reports)
        }
        .tint(PetSignalTheme.coral)
        .sheet(isPresented: $isPresentingNewReport) {
            NewReportView { _ in
                toastTask?.cancel()
                savedMessage = "Radar signal broadcasted on this device"
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "Radar signal broadcasted on this device"
                )
                selectedTab = .reports
                toastTask = Task {
                    try? await Task.sleep(for: .seconds(3))
                    guard !Task.isCancelled else { return }
                    savedMessage = nil
                }
            }
        }
        .overlay(alignment: .top) {
            if let savedMessage {
                Label(savedMessage, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 48)
                    .background(PetSignalTheme.emerald, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.top, 8)
                    .accessibilityAddTraits(.isStaticText)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: savedMessage)
    }
}

private enum AppTab: Hashable {
    case map
    case reports
}

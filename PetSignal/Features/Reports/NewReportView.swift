import MapKit
import PhotosUI
import SwiftUI
import UIKit

struct NewReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ReportStore.self) private var reportStore
    @State private var draft = ReportDraft()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var locationWasSelected = false
    @State private var hasEditedDraft = false
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393),
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
    )

    private var canSubmit: Bool {
        !draft.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && locationWasSelected
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What happened?") {
                    Picker("Report type", selection: $draft.kind) {
                        ForEach(ReportKind.allCases) { kind in
                            Label(kind.rawValue, systemImage: kind.systemImage).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Animal", selection: $draft.species) {
                        ForEach(AnimalSpecies.allCases) { species in
                            Text(species.rawValue).tag(species)
                        }
                    }

                    if draft.kind == .missing {
                        TextField("Pet name", text: $draft.petName)
                    }
                    DatePicker("Last seen", selection: $draft.lastSeenAt, in: ...Date())
                }

                Section("Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let imageData = draft.imageData, let image = UIImage(data: imageData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 190)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        } else {
                            Label("Choose a clear photo", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity, minHeight: 80)
                        }
                    }
                    .onChange(of: selectedPhoto) { _, photo in
                        Task {
                            let imageData = try? await photo?.loadTransferable(type: Data.self)
                            guard selectedPhoto == photo else { return }
                            draft.imageData = imageData
                        }
                    }
                }

                Section("Description") {
                    TextField("Short description", text: $draft.summary, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Color, collar, behavior, direction of travel...", text: $draft.details, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    MapReader { proxy in
                        Map(position: $cameraPosition) {
                            Marker("Last seen", coordinate: draft.location.coordinate)
                                .tint(draft.kind.tint)
                        }
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .onTapGesture { point in
                            guard let coordinate = proxy.convert(point, from: .local) else { return }
                            draft.location = GeoPoint(
                                latitude: coordinate.latitude,
                                longitude: coordinate.longitude
                            )
                            locationWasSelected = true
                        }
                    }
                } header: {
                    Text("Last seen location")
                } footer: {
                    Text(locationWasSelected
                         ? "The pin shows the public approximate area, not a private address."
                         : "Required: tap the map to place the pin at an approximate last-seen area.")
                }
            }
            .navigationTitle(draft.kind == .missing ? "Missing pet" : "New sighting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publish") {
                        reportStore.add(draft)
                        dismiss()
                    }
                    .disabled(!canSubmit)
                }
            }
        }
        .onChange(of: draft) { _, _ in
            hasEditedDraft = true
        }
        .interactiveDismissDisabled(hasEditedDraft || locationWasSelected)
    }
}

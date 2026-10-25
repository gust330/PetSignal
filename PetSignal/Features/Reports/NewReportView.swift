import MapKit
import PhotosUI
import SwiftUI
import UIKit

struct NewReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ReportStore.self) private var reportStore

    private let followingUpOn: AnimalReport?
    private let onPublished: (UUID) -> Void

    @State private var draft: ReportDraft
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var locationWasSelected = false
    @State private var hasEditedDraft = false
    @State private var isProcessingPhoto = false
    @State private var photoLoadID = UUID()
    @State private var photoError: String?
    @State private var isShowingDiscardConfirmation = false
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393),
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
    )

    init(
        followingUpOn: AnimalReport? = nil,
        onPublished: @escaping (UUID) -> Void = { _ in }
    ) {
        self.followingUpOn = followingUpOn
        self.onPublished = onPublished
        var draft = ReportDraft()
        if let followingUpOn {
            draft.kind = followingUpOn.kind == .missing ? .sighting : .missing
            draft.species = followingUpOn.species
            draft.linkedReportID = followingUpOn.id
        }
        _draft = State(initialValue: draft)
    }

    private var canSubmit: Bool {
        !draft.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && locationWasSelected
            && !isProcessingPhoto
    }

    var body: some View {
        NavigationStack {
            Form {
                introSection

                if let followingUpOn {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "link.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color.petSignalGreen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Following up on \(followingUpOn.displayName)")
                                    .font(.headline)
                                Text("This report will be connected for the community.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                detailsSection
                photoSection
                descriptionSection
                locationSection
                validationSection
            }
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .secondarySystemBackground))
            .tint(Color.petSignalGreen)
            .navigationTitle(draft.kind == .missing ? "Missing pet" : "New sighting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasEditedDraft || selectedPhoto != nil || isProcessingPhoto {
                            isShowingDiscardConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publish") {
                        let reportID = reportStore.add(draft)
                        onPublished(reportID)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!canSubmit)
                }
            }
        }
        .onChange(of: draft) { _, _ in
            hasEditedDraft = true
        }
        .interactiveDismissDisabled(hasEditedDraft || selectedPhoto != nil || isProcessingPhoto)
        .confirmationDialog(
            "Discard this report?",
            isPresented: $isShowingDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard report", role: .destructive) { dismiss() }
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("Your photos and details have not been published.")
        }
    }

    private var introSection: some View {
        Section {
            HStack(spacing: 14) {
                SignalMark(size: 54)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Send a useful signal")
                        .font(.title3.weight(.bold))
                    Text("Clear details and an approximate location help nearby people act quickly.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var detailsSection: some View {
        Section("What happened?") {
            Picker("Report type", selection: $draft.kind) {
                ForEach(ReportKind.allCases) { kind in
                    Label(kind.rawValue, systemImage: kind.systemImage).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .disabled(followingUpOn != nil)

            Picker("Animal", selection: $draft.species) {
                ForEach(AnimalSpecies.allCases) { species in
                    Label(species.rawValue, systemImage: species.systemImage).tag(species)
                }
            }
            .disabled(followingUpOn != nil)

            if draft.kind == .missing {
                TextField("Pet name (optional)", text: $draft.petName)
                    .textContentType(.name)
            }
            DatePicker("Last seen", selection: $draft.lastSeenAt, in: ...Date())
        }
    }

    private var photoSection: some View {
        Section {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    if let imageData = draft.imageData, let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 210)
                            .clipped()
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.title)
                            Text("Add a clear photo")
                                .font(.headline)
                            Text("Photos are resized and location metadata is removed.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 150)
                    }

                    if isProcessingPhoto {
                        Rectangle().fill(.black.opacity(0.35))
                        ProgressView("Preparing photo")
                            .tint(.white)
                            .foregroundStyle(.white)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isProcessingPhoto)
            .onChange(of: selectedPhoto) { _, photo in
                if photo != nil {
                    hasEditedDraft = true
                }
                loadPhoto(photo)
            }

            if draft.imageData != nil {
                Button(role: .destructive) {
                    photoLoadID = UUID()
                    isProcessingPhoto = false
                    selectedPhoto = nil
                    draft.imageData = nil
                } label: {
                    Label("Remove photo", systemImage: "trash")
                }
            }

            if let photoError {
                Label(photoError, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Photo")
        } footer: {
            Text(draft.kind == .missing
                 ? "Use a photo that clearly shows the face, coat, and distinctive markings."
                 : "Photograph from a safe distance. Do not chase the animal for a better picture.")
        }
    }

    private var descriptionSection: some View {
        Section("Description") {
            TextField(summaryPrompt, text: $draft.summary, axis: .vertical)
                .lineLimit(2...4)
            TextField(detailsPrompt, text: $draft.details, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var locationSection: some View {
        Section {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    if locationWasSelected {
                        MapCircle(center: draft.location.coordinate, radius: 130)
                            .foregroundStyle(draft.kind.tint.opacity(0.2))
                        Marker("Approximate area", coordinate: draft.location.coordinate)
                            .tint(draft.kind.tint)
                    }
                }
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(alignment: .top) {
                    if !locationWasSelected {
                        Label("Tap the map to place the area", systemImage: "hand.tap.fill")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(.regularMaterial, in: Capsule())
                            .padding(10)
                    }
                }
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
            Text("Approximate last-seen area")
        } footer: {
            Text(locationWasSelected
                 ? "The public coordinate is placed on a roughly 300-metre grid before publishing."
                 : "Required. Never pinpoint a private home or your live location.")
        }
    }

    @ViewBuilder
    private var validationSection: some View {
        if !canSubmit {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Before publishing")
                        .font(.headline)
                    validationRow("Add a short description", complete: !draft.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    validationRow("Choose an approximate area", complete: locationWasSelected)
                    if isProcessingPhoto {
                        validationRow("Wait for the photo to finish", complete: false)
                    }
                }
            }
        }
    }

    private var summaryPrompt: String {
        draft.kind == .missing
            ? "Color, size, and distinctive markings"
            : "What did the animal look like?"
    }

    private var detailsPrompt: String {
        draft.kind == .missing
            ? "Collar, temperament, medical needs, where they may hide..."
            : "Condition, direction of travel, collar, and whether still visible..."
    }

    private func validationRow(_ title: String, complete: Bool) -> some View {
        Label(title, systemImage: complete ? "checkmark.circle.fill" : "circle")
            .font(.subheadline)
            .foregroundStyle(complete ? Color.petSignalGreen : .secondary)
    }

    private func loadPhoto(_ photo: PhotosPickerItem?) {
        guard let photo else { return }
        let loadID = UUID()
        photoLoadID = loadID
        isProcessingPhoto = true
        photoError = nil
        Task {
            defer {
                if photoLoadID == loadID {
                    isProcessingPhoto = false
                }
            }
            do {
                guard let data = try await photo.loadTransferable(type: Data.self),
                      photoLoadID == loadID,
                      selectedPhoto == photo,
                      let sanitizedData = ImageSanitizer.sanitizedJPEGData(from: data) else {
                    if photoLoadID == loadID, selectedPhoto == photo {
                        photoError = "That photo could not be prepared. Try another image."
                    }
                    return
                }
                draft.imageData = sanitizedData
            } catch {
                guard photoLoadID == loadID, selectedPhoto == photo else { return }
                photoError = "That photo could not be loaded. Try another image."
            }
        }
    }
}

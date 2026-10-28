import MapKit
import PhotosUI
import SwiftUI
import UIKit

struct NewReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(ReportStore.self) private var reportStore

    private let followingUpOn: AnimalReport?
    private let onPublished: (UUID) -> Void

    @State private var draft: ReportDraft
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var locationWasSelected = false
    @State private var mapCenter = CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393)
    @State private var locationQuery = ""
    @State private var selectedPlaceName: String?
    @State private var locationError: String?
    @State private var isSearchingLocation = false
    @State private var locationSearchTask: Task<Void, Never>?
    @State private var hasEditedDraft = false
    @State private var isProcessingPhoto = false
    @State private var photoLoadID = UUID()
    @State private var photoError: String?
    @State private var publishError: String?
    @State private var isShowingDiscardConfirmation = false
    @State private var selectedTraits: Set<String> = []
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393),
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
    )

    private let quickTraits = [
        "Wearing Collar", "Friendly", "Skittish / Do Not Chase", "Microchipped", "No Collar", "Needs Vet Care"
    ]

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
                if let followingUpOn {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "link.circle.fill")
                                .font(.title2)
                                .foregroundStyle(PetSignalTheme.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Following up on \(followingUpOn.displayName)")
                                    .font(.subheadline.weight(.bold))
                                Text("This report will be linked on this device.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                categorySection
                photoSection
                identificationSection
                approximateAreaSection
                traitsAndNotesSection
                validationSection
            }
            .scrollContentBackground(.hidden)
            .background(PetSignalTheme.canvas)
            .tint(PetSignalTheme.green)
            .navigationTitle(draft.kind == .missing ? "Missing Pet Report" : "Animal Sighting")
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
                    Button("Post") {
                        submitReport()
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
            Text("Your photos and report details have not been saved.")
        }
        .alert(
            "Unable to save",
            isPresented: Binding(
                get: { publishError != nil },
                set: { if !$0 { publishError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { publishError = nil }
        } message: {
            Text(publishError ?? "")
        }
    }

    // MARK: - Section 1: Category

    private var categorySection: some View {
        Section {
            Picker("Report Type", selection: $draft.kind) {
                ForEach(ReportKind.allCases) { kind in
                    Label(kind.rawValue, systemImage: kind.systemImage).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .disabled(followingUpOn != nil)
        } header: {
            Text("1. Report Category")
        }
    }

    // MARK: - Section 2: Privacy-Safe Photo

    private var photoSection: some View {
        Section {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    if let imageData = draft.imageData, let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.badge.ellipsis")
                                .font(.system(size: 34))
                                .foregroundStyle(PetSignalTheme.green)
                            Text("Select Animal Photo")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("EXIF GPS metadata is automatically stripped before upload.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 140)
                    }

                    if isProcessingPhoto {
                        Rectangle().fill(.black.opacity(0.4))
                        ProgressView("Sanitizing photo...")
                            .tint(.white)
                            .foregroundStyle(.white)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(isProcessingPhoto)
            .accessibilityLabel(draft.imageData == nil ? "Select animal photo" : "Change selected photo")
            .onChange(of: selectedPhoto) { _, photo in
                if photo != nil {
                    hasEditedDraft = true
                    draft.imageData = nil
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
                        .font(.subheadline)
                }
            }

            if let photoError {
                Label(photoError, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("2. Privacy-Safe Photo")
        } footer: {
            Text(draft.kind == .missing
                 ? "Select a photo clearly showing distinctive fur markings or collar."
                 : "Photograph from a safe distance. Never chase an animal for a picture.")
        }
    }

    // MARK: - Section 3: Animal Identification

    private var identificationSection: some View {
        Section {
            Picker("Species", selection: $draft.species) {
                ForEach(AnimalSpecies.allCases) { species in
                    Label(species.rawValue, systemImage: species.systemImage).tag(species)
                }
            }
            .disabled(followingUpOn != nil)

            if draft.kind == .missing {
                TextField("Pet Name (e.g., Luna)", text: $draft.petName)
                    .textContentType(.name)
            }

            TextField(
                draft.kind == .missing ? "Short description (e.g., Golden Retriever mix)" : "What did the animal look like?",
                text: $draft.summary
            )

            DatePicker("Last Seen", selection: $draft.lastSeenAt, in: ...Date())
        } header: {
            Text("3. Animal Identification")
        }
    }

    // MARK: - Section 4: Approximate Area

    private var approximateAreaSection: some View {
        Section {
            HStack {
                TextField("Neighborhood, landmark, or street", text: $locationQuery)
                    .textContentType(.fullStreetAddress)
                    .submitLabel(.search)
                    .onSubmit(searchForLocation)
                    .onChange(of: locationQuery) { _, _ in
                        locationSearchTask?.cancel()
                        isSearchingLocation = false
                        locationWasSelected = false
                        selectedPlaceName = nil
                        locationError = nil
                    }

                if isSearchingLocation {
                    ProgressView()
                        .padding(.trailing, 4)
                }
            }

            Button(action: searchForLocation) {
                Label(isSearchingLocation ? "Searching..." : "Find Neighborhood", systemImage: "magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .disabled(locationQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearchingLocation)

            if let locationError {
                Label(locationError, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            ZStack {
                Map(position: $cameraPosition) {
                    if locationWasSelected {
                        MapCircle(center: draft.location.coordinate, radius: 300)
                            .foregroundStyle(draft.kind.tint.opacity(0.24))
                            .stroke(draft.kind.tint, lineWidth: 2)
                        Marker("Approximate Zone", coordinate: draft.location.coordinate)
                            .tint(draft.kind.tint)
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onMapCameraChange(frequency: .continuous) { context in
                    mapCenter = context.region.center
                }
                .accessibilityHidden(true)

                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(PetSignalTheme.green)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(PetSignalTheme.border.opacity(0.5), lineWidth: 1))
                    .accessibilityHidden(true)
            }

            Button {
                draft.location = GeoPoint(
                    latitude: mapCenter.latitude,
                    longitude: mapCenter.longitude
                )
                selectedPlaceName = "Map Center Area"
                locationWasSelected = true
            } label: {
                Label(
                    locationWasSelected ? "Update to Map Center" : "Set Area to Map Center",
                    systemImage: "scope"
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)

            if locationWasSelected {
                LabeledContent("Area Name", value: selectedPlaceName ?? "Selected Area")
                LabeledContent("Privacy Grid Coordinates", value: draft.location.approximateAreaDescription)
            }
        } header: {
            Text("4. Approximate Area (~300m Zone)")
        } footer: {
            Text("Exact coordinates are never published. Public locations are snapped to a roughly 300-meter privacy grid.")
        }
    }

    // MARK: - Section 5: Distinguishing Traits & Notes

    private var traitsAndNotesSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickTraits, id: \.self) { trait in
                        let isSelected = selectedTraits.contains(trait)
                        Button {
                            if isSelected {
                                selectedTraits.remove(trait)
                            } else {
                                selectedTraits.insert(trait)
                            }
                        } label: {
                            Text(trait)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    isSelected ? AnyShapeStyle(PetSignalTheme.green) : AnyShapeStyle(PetSignalTheme.subtleSurface),
                                    in: Capsule()
                                )
                                .foregroundStyle(isSelected ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            TextField("Collar, temperament, direction of travel, or where they may hide...", text: $draft.details, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("5. Distinguishing Traits & Behavior Notes")
        }
    }

    // MARK: - Validation Checklist

    @ViewBuilder
    private var validationSection: some View {
        if !canSubmit {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Before Publishing")
                        .font(.subheadline.weight(.bold))
                    validationRow("Add a short description", complete: !draft.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    validationRow("Choose an approximate area", complete: locationWasSelected)
                    if isProcessingPhoto {
                        validationRow("Wait for photo sanitization to complete", complete: false)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func validationRow(_ title: String, complete: Bool) -> some View {
        Label(title, systemImage: complete ? "checkmark.circle.fill" : "circle")
            .font(.footnote)
            .foregroundStyle(complete ? PetSignalTheme.green : .secondary)
            .accessibilityValue(complete ? "Complete" : "Required")
    }

    // MARK: - Actions

    private func submitReport() {
        var finalDraft = draft
        if !selectedTraits.isEmpty {
            let traitsString = selectedTraits.sorted().joined(separator: ", ")
            if finalDraft.details.isEmpty {
                finalDraft.details = "Traits: \(traitsString)."
            } else {
                finalDraft.details += " (Traits: \(traitsString))"
            }
        }

        do {
            let reportID = try reportStore.add(finalDraft)
            onPublished(reportID)
            dismiss()
        } catch {
            publishError = "This report could not be saved. Check the location and photo, then try again."
        }
    }

    private func searchForLocation() {
        let query = locationQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        locationSearchTask?.cancel()
        isSearchingLocation = true
        locationError = nil

        locationSearchTask = Task {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            do {
                let response = try await MKLocalSearch(request: request).start()
                try Task.checkCancellation()
                guard locationQuery.trimmingCharacters(in: .whitespacesAndNewlines) == query else {
                    isSearchingLocation = false
                    return
                }
                guard let mapItem = response.mapItems.first else {
                    locationError = "No area was found. Try a neighborhood or landmark."
                    isSearchingLocation = false
                    return
                }
                let coordinate = mapItem.placemark.coordinate
                mapCenter = coordinate
                selectedPlaceName = mapItem.name ?? mapItem.placemark.title ?? query
                draft.location = GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
                locationWasSelected = true
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
                    )
                )
                isSearchingLocation = false
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                locationError = "That area could not be found. Check the text and try again."
                isSearchingLocation = false
            }
        }
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

import MapKit
import SwiftUI

struct MapView: View {
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var locationManager: LocationManager
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var pendingMapItem: MKMapItem?
    @State private var searchSheetDetent: PresentationDetent = .medium
    @State private var addRestaurantSheetDetent: PresentationDetent = .medium

    var body: some View {
        Map(position: $cameraPosition, selection: $viewModel.selection) {
            UserAnnotation()

            ForEach(viewModel.displayedPins) { pin in
                Marker(pin.name, coordinate: pin.coordinate)
                    .tint(tintColor(for: pin.kind))
                    .tag(pin.id)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .overlay(alignment: .top) {
            if let errorMessage = viewModel.errorMessage {
                hintBanner(errorMessage)
            }
        }
        .overlay {
            if (viewModel.isLoading && viewModel.restaurants.isEmpty) || viewModel.isResolvingMapFeature {
                ProgressView()
            } else if viewModel.showsEmptyMapHint {
                emptyMapHint
            }
        }
        .overlay(alignment: .bottom) {
            if !viewModel.isSearchSheetPresented {
                searchTrigger
                    .padding(.bottom, 8)
            }
        }
        .onChange(of: viewModel.selection) { _, newValue in
            handleSelection(newValue)
        }
        .onChange(of: viewModel.searchResults) { _, results in
            // Bei "Umgebung" bleibt die Kamera bewusst auf der Nutzer-Location
            // zentriert - nur die globale Suche zoomt auf die Bounding-Box
            // aller Treffer, da man dort über größere Distanzen sucht.
            guard viewModel.searchScope == .global else { return }
            fitCamera(to: results.map(\.coordinate))
        }
        .sheet(item: $viewModel.selectedRestaurant, onDismiss: {
            viewModel.selection = nil
            viewModel.focusedRestaurant = nil
            Task { await viewModel.loadPins() }
        }) { restaurant in
            RestaurantDetailSheet(restaurant: restaurant)
        }
        .sheet(isPresented: $viewModel.isShowingAddRestaurant, onDismiss: {
            viewModel.restaurantSearchResults = []
            // Erst NACHDEM dieses Sheet vollständig geschlossen ist das
            // nächste (RestaurantDetailSheet) öffnen - zwei Sheets
            // gleichzeitig zu präsentieren/schließen kann die SwiftUI-
            // Sheet-Verwaltung zum Hängen bringen.
            if let mapItem = pendingMapItem {
                pendingMapItem = nil
                Task { await handleAddedRestaurant(mapItem) }
            }
        }) {
            AddRestaurantSearchView(locationManager: locationManager) { mapItem in
                pendingMapItem = mapItem
            } onResultsChanged: { items in
                viewModel.restaurantSearchResults = items
                fitCamera(to: items.map(\.placemark.coordinate))
            }
            .presentationDetents([.medium, .large], selection: $addRestaurantSheetDetent)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .presentationBackground(
                addRestaurantSheetDetent == .medium
                    ? AnyShapeStyle(Material.ultraThinMaterial.opacity(0.7))
                    : AnyShapeStyle(Color(.systemGroupedBackground))
            )
        }
        .sheet(isPresented: $viewModel.isSearchSheetPresented, onDismiss: {
            if let pending = viewModel.pendingSearchSelection {
                viewModel.pendingSearchSelection = nil
                viewModel.focusedRestaurant = pending.summary
                viewModel.selection = MapSelection(pending.restaurantId)
                viewModel.selectedRestaurant = pending.summary
            }
        }) {
            SearchResultsSheet(viewModel: viewModel, locationManager: locationManager)
                .presentationDetents([.medium, .large], selection: $searchSheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationBackground(
                    searchSheetDetent == .medium
                        ? AnyShapeStyle(Material.ultraThinMaterial.opacity(0.7))
                        : AnyShapeStyle(Color(.systemGroupedBackground))
                )
        }
        .task {
            locationManager.requestAuthorization()
            locationManager.requestLocation()
            await viewModel.loadPins()
        }
    }

    /// Eigene Pins (getaggt) landen als `.value`, native Apple-Maps-POI-Taps
    /// als `.feature`. Bei Letzterem wird bei Bedarf ein lokaler Eintrag
    /// angelegt - genau wie über die "+"-Suche, nur direkt auf der Karte.
    private func handleSelection(_ newValue: MapSelection<MapPin.ID>?) {
        guard let newValue else { return }

        if let pinID = newValue.value {
            viewModel.selectedRestaurant = viewModel.restaurantSummary(for: pinID)
            return
        }

        guard
            let feature = newValue.feature,
            let category = feature.pointOfInterestCategory,
            MKPointOfInterestCategory.foodAndDrink.contains(category)
        else {
            viewModel.selection = nil
            return
        }

        Task {
            do {
                let request = MKMapItemRequest(feature: feature)
                let mapItem = try await request.mapItem
                if let restaurant = await viewModel.resolveRestaurant(from: mapItem) {
                    viewModel.selectedRestaurant = restaurant
                } else {
                    viewModel.selection = nil
                }
            } catch {
                viewModel.errorMessage = error.localizedDescription
                viewModel.selection = nil
            }
        }
    }

    /// Treffer aus der "+"-Suche verhält sich wie ein Tap auf der Karte:
    /// erst dorthin zentrieren (Apples eigenes POI-Icon wird dort sichtbar),
    /// dann dieselbe Detailseite mit Merken/Bewerten öffnen.
    private func handleAddedRestaurant(_ mapItem: MKMapItem) async {
        guard let restaurant = await viewModel.resolveRestaurant(from: mapItem) else { return }
        viewModel.focusedRestaurant = restaurant
        viewModel.selection = MapSelection(restaurant.id)
        viewModel.selectedRestaurant = restaurant
        withAnimation {
            cameraPosition = .region(
                centerRegion(
                    MKCoordinateRegion(
                        center: restaurant.coordinate,
                        latitudinalMeters: 600,
                        longitudinalMeters: 600
                    )
                )
            )
        }
    }

    /// Zoomt/fliegt so, dass alle übergebenen Koordinaten sichtbar sind
    /// (mit etwas Rand). Wird für Such- und Restaurant-Suchergebnisse
    /// gleichermaßen verwendet.
    private func fitCamera(to coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }

        if coordinates.count == 1, let only = coordinates.first {
            withAnimation {
                cameraPosition = .region(
                    centerRegion(MKCoordinateRegion(center: only, latitudinalMeters: 800, longitudinalMeters: 800))
                )
            }
            return
        }

        let lats = coordinates.map(\.latitude)
        let lngs = coordinates.map(\.longitude)
        guard
            let minLat = lats.min(), let maxLat = lats.max(),
            let minLng = lngs.min(), let maxLng = lngs.max()
        else { return }

        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLng + maxLng) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.02),
            longitudeDelta: max((maxLng - minLng) * 1.5, 0.02)
        )

        withAnimation {
            cameraPosition = .region(centerRegion(MKCoordinateRegion(center: center, span: span)))
        }
    }

    /// Ob gerade ein Sheet die untere Bildschirmhälfte verdeckt (Such-,
    /// "+"- oder Detail-Sheet jeweils im `.medium`-Detent). Bei `.large`
    /// oder ganz ohne Sheet ist die Karte voll sichtbar. Das Detail-Sheet
    /// hat keinen eigenen Detent-Tracking-Binding (das brach das direkte
    /// Öffnen auf `.medium`), daher wird hier einfach angenommen, dass es
    /// beim Öffnen immer bei `.medium` startet - was für die Kamera-
    /// Zentrierung in genau diesem Moment auch der relevante Fall ist.
    private var isHalfPageSheetActive: Bool {
        if viewModel.isSearchSheetPresented, searchSheetDetent == .medium { return true }
        if viewModel.isShowingAddRestaurant, addRestaurantSheetDetent == .medium { return true }
        if viewModel.selectedRestaurant != nil { return true }
        return false
    }

    /// Verschiebt das Zentrum einer Region nach Süden, wenn ein Sheet die
    /// untere Hälfte verdeckt - sonst würde der Zielpunkt in der Bildschirm-
    /// mitte landen, also genau unter/am Rand des Sheets statt in der Mitte
    /// des tatsächlich sichtbaren (oberen) Kartenbereichs.
    private func centerRegion(_ region: MKCoordinateRegion) -> MKCoordinateRegion {
        guard isHalfPageSheetActive else { return region }
        var adjusted = region
        adjusted.center.latitude -= region.span.latitudeDelta * 0.25
        return adjusted
    }

    private func tintColor(for kind: MapPin.Kind) -> Color {
        switch kind {
        case .rated: viewModel.isSearchSheetPresented ? .orange : .accentColor
        case .bookmarked: .purple
        case .searchResult: .orange
        }
    }

    private var searchTrigger: some View {
        Button {
            viewModel.isSearchSheetPresented = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                Text(viewModel.searchText.isEmpty ? "Gericht suchen, z. B. Ramen" : viewModel.searchText)
                    .foregroundStyle(viewModel.searchText.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(12)
            .glassCapsuleBackground()
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    private var emptyMapHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife.circle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Noch keine Restaurants in der Nähe")
                .font(.headline)
            Text("Tippe auf ein Restaurant-Icon auf der Karte oder oben rechts auf „+“, um loszulegen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
        .padding(.horizontal, 40)
        .allowsHitTesting(false)
    }

    private func hintBanner(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: .rect(cornerRadius: 10))
            .padding(.top, 8)
            .padding(.horizontal, 16)
    }
}

private extension View {
    /// Liquid-Glass-Optik (iOS 26+) wie bei den nativen Map-Controls,
    /// mit Material-Fallback für ältere Systeme.
    @ViewBuilder
    func glassCapsuleBackground() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .capsule)
        } else {
            self.background(.thickMaterial, in: .capsule)
        }
    }
}

#Preview {
    MapView(viewModel: MapViewModel(), locationManager: LocationManager())
}

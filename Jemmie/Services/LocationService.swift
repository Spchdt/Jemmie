import Foundation
import CoreLocation

@Observable
@MainActor
final class LocationService: NSObject {
    private let manager = CLLocationManager()
    
    private var lastKnownLocation: CLLocationCoordinate2D?
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestLocation() async -> CLLocationCoordinate2D? {
        if let loc = lastKnownLocation {
            return loc
        }
        
        // Request auth if not determined
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        
        guard manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.lastKnownLocation = location.coordinate
            self.locationContinuation?.resume(returning: location.coordinate)
            self.locationContinuation = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[Location] Failed: \(error.localizedDescription)")
        Task { @MainActor in
            self.locationContinuation?.resume(returning: nil)
            self.locationContinuation = nil
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
                self.locationContinuation?.resume(returning: nil)
                self.locationContinuation = nil
            }
        }
    }
}

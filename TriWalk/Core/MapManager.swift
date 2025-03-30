//
//  MapManger.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/30/25.
//

import UIKit
import MapKit
import CoreLocation
import Combine

// MARK: - MapManager
final class MapManager {
    // MARK: - Singleton
    static let shared = MapManager()
    
    // MARK: - Properties
    private let searchSubject = PassthroughSubject<[MKMapItem], Error>()
    
    // MARK: - Public properties
    var searchResultsPublisher: AnyPublisher<[MKMapItem], Error> {
        return searchSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// 장소 검색
    func searchLocations(query: String, region: MKCoordinateRegion? = nil) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        if let region = region {
            request.region = region
        } else {
            request.region = MKCoordinateRegion(.world)
        }
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] (response, error) in
            if let error = error {
                self?.searchSubject.send(completion: .failure(error))
                return
            }
            
            if let response = response {
                self?.searchSubject.send(response.mapItems)
            } else {
                let noResultsError = NSError(domain: "com.app.map", code: 1, userInfo: [NSLocalizedDescriptionKey: "검색 결과가 없습니다."])
                self?.searchSubject.send(completion: .failure(noResultsError))
            }
        }
    }
    
    /// 두 좌표 간 거리 계산 (미터 단위)
    func distance(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> CLLocationDistance {
        let sourceLocation = CLLocation(latitude: source.latitude, longitude: source.longitude)
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return sourceLocation.distance(from: destinationLocation)
    }
    
    /// 두 좌표가 모두 보이도록 지도 범위 조정
    func showAnnotations(_ mapView: MKMapView, _ annotations: [MKAnnotation], animated: Bool = true) {
        mapView.showAnnotations(annotations, animated: animated)
    }
    
    /// 마커 생성 (커스텀 이미지 옵션)
    func createMarker(at coordinate: CLLocationCoordinate2D, title: String, subtitle: String? = nil, image: UIImage? = nil) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        annotation.subtitle = subtitle
        return annotation
    }
}

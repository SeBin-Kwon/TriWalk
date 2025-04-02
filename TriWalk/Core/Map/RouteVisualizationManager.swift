//
//  RouteVisualizationManager.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/2/25.
//

import MapKit
import UIKit
import Combine

/// 산책 경로 시각화를 위한 유틸리티 클래스
final class RouteVisualizationManager {
    
    // MARK: - Nested Types
    
    /// 지도에 표시할 경로 아이템
    struct RouteItem {
        let walkRecord: WalkRecord
        let routeCoordinates: [CLLocationCoordinate2D]
        let color: UIColor
        let lineWidth: CGFloat
        let identifier: String
        
        init(
            walkRecord: WalkRecord,
            routeCoordinates: [CLLocationCoordinate2D],
            color: UIColor = .triWalkPrimary,
            lineWidth: CGFloat = 4.0,
            identifier: String = UUID().uuidString
        ) {
            self.walkRecord = walkRecord
            self.routeCoordinates = routeCoordinates
            self.color = color
            self.lineWidth = lineWidth
            self.identifier = identifier
        }
    }
    
    // MARK: - Public Methods
    
    /// 현재 생성 중인 경로 시각화 (실시간 트래킹용)
    /// - Parameters:
    ///   - mapView: 경로를 표시할 지도 뷰
    ///   - coordinates: 경로 좌표 배열
    ///   - color: 경로 색상
    ///   - lineWidth: 경로 선 굵기
    /// - Returns: 추가된 경로 오버레이
    @discardableResult
    static func visualizeCurrentRoute(
        on mapView: MKMapView,
        coordinates: [CLLocationCoordinate2D],
        color: UIColor = .triWalkPrimary,
        lineWidth: CGFloat = 5.0
    ) -> RouteOverlay? {
        // 유효한 경로 좌표가 있는지 확인
        guard coordinates.count >= 2 else { return nil }
        
        // 기존 CurrentRoute 태그가 있는 오버레이 제거
        mapView.overlays.forEach { overlay in
            if let routeOverlay = overlay as? RouteOverlay, routeOverlay.tag == "CurrentRoute" {
                mapView.removeOverlay(routeOverlay)
            }
        }
        
        // 새 경로 오버레이 생성 및 추가
        let polyline = RouteOverlay(
            coordinates: coordinates,
            count: coordinates.count
        )
        polyline.color = color
        polyline.lineWidth = lineWidth
        polyline.tag = "CurrentRoute"
        
        mapView.addOverlay(polyline)
        return polyline
    }
    
    /// 여러 과거 경로 시각화 (투명도 그라데이션 적용)
    /// - Parameters:
    ///   - mapView: 경로를 표시할 지도 뷰
    ///   - routeItems: 표시할 경로 아이템 배열
    ///   - fadeOlder: 오래된 기록을 연하게 표시할지 여부
    static func visualizeHistoricalRoutes(
        on mapView: MKMapView,
        routeItems: [RouteItem],
        fadeOlder: Bool = true
    ) {
        // 기존 모든 오버레이 제거
        let existingOverlays = mapView.overlays.filter {
            ($0 as? RouteOverlay)?.tag != "CurrentRoute"
        }
        mapView.removeOverlays(existingOverlays)
        
        guard !routeItems.isEmpty else { return }
        
        // 모든 경로에 대한 좌표 수집
        var allCoordinates: [CLLocationCoordinate2D] = []
        
        // 경로 순서대로 오버레이 추가 (역순으로 추가하여 최신 경로가 위에 그려지도록)
        for (index, item) in routeItems.enumerated().reversed() {
            guard item.routeCoordinates.count >= 2 else { continue }
            
            // 투명도 계산 (최신: 1.0, 가장 오래된: 0.3)
            let opacity: CGFloat = fadeOlder ?
                1.0 - (CGFloat(index) / CGFloat(routeItems.count) * 0.7) :
                1.0
            
            // 색상 조정 (투명도 적용)
            let adjustedColor = item.color.withAlphaComponent(opacity)
            
            // 경로 오버레이 생성 및 추가
            let polyline = RouteOverlay(
                coordinates: item.routeCoordinates,
                count: item.routeCoordinates.count
            )
            polyline.color = adjustedColor
            polyline.lineWidth = item.lineWidth
            polyline.tag = item.identifier
            
            mapView.addOverlay(polyline)
            allCoordinates.append(contentsOf: item.routeCoordinates)
        }
        
        // 모든 경로가 보이도록 지도 범위 조정
        adjustMapViewToShowAllRoutes(mapView, coordinates: allCoordinates)
    }
    
    /// 특정 시간 구간 경로 시각화 (실시간 트래킹 진행 상황 표시용)
    /// - Parameters:
    ///   - mapView: 경로를 표시할 지도 뷰
    ///   - coordinates: 전체 경로 좌표
    ///   - startIndex: 시작 인덱스
    ///   - endIndex: 끝 인덱스
    ///   - color: 경로 색상
    ///   - lineWidth: 경로 선 굵기
    static func visualizeRouteSegment(
        on mapView: MKMapView,
        coordinates: [CLLocationCoordinate2D],
        startIndex: Int,
        endIndex: Int,
        color: UIColor = .triWalkPrimary,
        lineWidth: CGFloat = 5.0
    ) {
        guard startIndex >= 0,
              endIndex < coordinates.count,
              startIndex < endIndex,
              coordinates.count >= 2 else { return }
        
        // 구간 좌표 추출
        let segmentCoordinates = Array(coordinates[startIndex...endIndex])
        
        // 오버레이 생성 및 추가
        let polyline = RouteOverlay(
            coordinates: segmentCoordinates,
            count: segmentCoordinates.count
        )
        polyline.color = color
        polyline.lineWidth = lineWidth
        polyline.tag = "segment-\(startIndex)-\(endIndex)"
        
        mapView.addOverlay(polyline)
    }
    
    // MARK: - Private Methods
    
    /// 모든 경로가 지도에 표시되도록 범위 조정
    private static func adjustMapViewToShowAllRoutes(
        _ mapView: MKMapView,
        coordinates: [CLLocationCoordinate2D]
    ) {
        guard !coordinates.isEmpty else { return }
        
        // 바운딩 박스 계산
        let boundingAnnotations = createBoundingBoxAnnotations(from: coordinates)
        
        // 지도 범위 조정 (바운딩 박스보다 약간 더 넓게 표시)
        mapView.showAnnotations(boundingAnnotations, animated: true)
        
        // 계산에만 사용한 어노테이션 제거
        mapView.removeAnnotations(boundingAnnotations)
    }
    
    /// 좌표 배열의 바운딩 박스를 생성하기 위한 어노테이션 생성
    private static func createBoundingBoxAnnotations(
        from coordinates: [CLLocationCoordinate2D]
    ) -> [MKAnnotation] {
        // 최대/최소 위도 경도 찾기
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLng = coordinates[0].longitude
        var maxLng = coordinates[0].longitude
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLng = min(minLng, coordinate.longitude)
            maxLng = max(maxLng, coordinate.longitude)
        }
        
        // 바운딩 박스의 모서리 좌표 생성 (약간의 여백 추가)
        let padding = 0.001 // 약 100m
        let topLeft = CLLocationCoordinate2D(latitude: maxLat + padding, longitude: minLng - padding)
        let topRight = CLLocationCoordinate2D(latitude: maxLat + padding, longitude: maxLng + padding)
        let bottomLeft = CLLocationCoordinate2D(latitude: minLat - padding, longitude: minLng - padding)
        let bottomRight = CLLocationCoordinate2D(latitude: minLat - padding, longitude: maxLng + padding)
        
        // 각 모서리에 대한 어노테이션 생성
        let annotations: [MKPointAnnotation] = [
            createInvisibleAnnotation(at: topLeft),
            createInvisibleAnnotation(at: topRight),
            createInvisibleAnnotation(at: bottomLeft),
            createInvisibleAnnotation(at: bottomRight)
        ]
        
        return annotations
    }
    
    /// 보이지 않는 어노테이션 생성 (지도 범위 계산용)
    private static func createInvisibleAnnotation(at coordinate: CLLocationCoordinate2D) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        return annotation
    }
}

// MARK: - 커스텀 경로 오버레이 클래스
class RouteOverlay: MKPolyline {
    var color: UIColor = .triWalkPrimary
    var lineWidth: CGFloat = 4.0
    var tag: String = ""
}

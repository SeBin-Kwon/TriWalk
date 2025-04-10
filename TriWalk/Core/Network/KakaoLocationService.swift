//
//  KakaoLocationService.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/9/25.
//

import Foundation
import Combine
import CoreLocation

protocol KakaoLocationServiceProtocol {
    func convertCoordinateToAddress(lat: Double, lng: Double) -> AnyPublisher<KakaoCoord2AddressResponse, Error>
    func searchPlaces(query: String) -> AnyPublisher<KakaoSearchResponse, Error>
    func formatAddress(from response: KakaoCoord2AddressResponse) -> String?
}

final class KakaoLocationService: KakaoLocationServiceProtocol {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager = .shared) {
        self.networkManager = networkManager
    }
    
    // 좌표 -> 주소 변환
    func convertCoordinateToAddress(lat: Double, lng: Double) -> AnyPublisher<KakaoCoord2AddressResponse, Error> {
        // 카카오 API는 경도(x), 위도(y) 순서로 요청
        let endpoint = KakaoEndpoint.coord2address(x: lng, y: lat)
        return networkManager.request(endpoint)
    }
    
    // 장소 검색
    func searchPlaces(query: String) -> AnyPublisher<KakaoSearchResponse, Error> {
        let endpoint = KakaoEndpoint.searchKeyword(query: query)
        return networkManager.request(endpoint)
    }
    
    // 주소 포맷팅 유틸리티 메서드
    func formatAddress(from response: KakaoCoord2AddressResponse) -> String? {
        guard let document = response.documents.first else {
            return nil
        }
        
        // 도로명 주소 처리
        if let roadAddress = document.roadAddress {
            // 건물명이 있으면 우선 사용
            if !roadAddress.buildingName.isEmpty {
                return roadAddress.buildingName
            }
            // 건물명이 없으면 도로명 사용
            else if !roadAddress.roadName.isEmpty {
                return roadAddress.roadName
            }
            // 둘 다 없으면 전체 도로명 주소 반환
//            return roadAddress.addressName
        }
        
        // 지번 주소 사용 (도로명 주소가 없는 경우)
        if let address = document.address {
            if !address.region3DepthName.isEmpty && !address.mainAddressNo.isEmpty {
                return address.region3DepthName + " " + address.mainAddressNo
            }
            if !address.region3DepthName.isEmpty  {
                return address.region3DepthName
            }
            return address.addressName
        }
        
        return nil
    }
}

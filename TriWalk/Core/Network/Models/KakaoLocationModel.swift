//
//  KakaoLocationModel.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/9/25.
//

import Foundation

// 좌표 -> 주소 변환 응답 모델
struct KakaoCoord2AddressResponse: Codable {
    let documents: [Document]
    let meta: Meta
    
    struct Document: Codable {
        let address: Address?
        let roadAddress: RoadAddress?
        
        enum CodingKeys: String, CodingKey {
            case address
            case roadAddress = "road_address"
        }
    }
    
    struct Address: Codable {
        let addressName: String
        let region1DepthName: String
        let region2DepthName: String
        let region3DepthName: String
        let mainAddressNo: String
        
        enum CodingKeys: String, CodingKey {
            case addressName = "address_name"
            case region1DepthName = "region_1depth_name"
            case region2DepthName = "region_2depth_name"
            case region3DepthName = "region_3depth_name"
            case mainAddressNo = "main_address_no"
        }
    }
    
    struct RoadAddress: Codable {
        let addressName: String
        let buildingName: String
        let roadName: String
        
        enum CodingKeys: String, CodingKey {
            case addressName = "address_name"
            case buildingName = "building_name"
            case roadName = "road_name"
        }
    }
    
    struct Meta: Codable {
        let totalCount: Int
        
        enum CodingKeys: String, CodingKey {
            case totalCount = "total_count"
        }
    }
}

// 키워드 검색 응답 모델
struct KakaoSearchResponse: Codable {
    let documents: [Document]
    let meta: Meta
    
    struct Document: Codable {
        let id: String
        let placeName: String
        let categoryName: String
        let addressName: String
        let roadAddressName: String
        let x: String // 경도(Longitude)
        let y: String // 위도(Latitude)
        
        enum CodingKeys: String, CodingKey {
            case id
            case placeName = "place_name"
            case categoryName = "category_name"
            case addressName = "address_name"
            case roadAddressName = "road_address_name"
            case x, y
        }
    }
    
    struct Meta: Codable {
        let pageableCount: Int
        let totalCount: Int
        let isEnd: Bool
        
        enum CodingKeys: String, CodingKey {
            case pageableCount = "pageable_count"
            case totalCount = "total_count"
            case isEnd = "is_end"
        }
    }
}

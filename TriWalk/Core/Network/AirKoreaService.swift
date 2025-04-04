//
//  AirKoreaService.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/4/25.
//

import Foundation
import Combine

protocol AirKoreaServiceProtocol {
    func fetchAirQuality(stationName: String) -> AnyPublisher<AirKoreaResponse, Error>
}

final class AirKoreaService: AirKoreaServiceProtocol {
    private let networkManager: NetworkManager
    private let apiKey: String
    
    init(networkManager: NetworkManager = .shared, apiKey: String = APIKey.airKorea) {
        self.networkManager = networkManager
        self.apiKey = apiKey
    }
    
    func fetchAirQuality(stationName: String) -> AnyPublisher<AirKoreaResponse, Error> {
        let endpoint = AirKoreaEndpoint.dustInfo(stationName: stationName, apiKey: apiKey)
        return networkManager.request(endpoint)
    }
}

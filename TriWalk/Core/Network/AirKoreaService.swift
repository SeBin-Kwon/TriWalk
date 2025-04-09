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
    
    init(networkManager: NetworkManager = .shared) {
        self.networkManager = networkManager
    }
    
    func fetchAirQuality(stationName: String) -> AnyPublisher<AirKoreaResponse, Error> {
        let endpoint = AirKoreaEndpoint.dustInfo(stationName: stationName)
        return networkManager.request(endpoint)
    }
}

//
//  WeatherService.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/4/25.
//

import Foundation
import Combine
import CoreLocation

protocol WeatherServiceProtocol {
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error>
}

final class WeatherService: WeatherServiceProtocol {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager = .shared) {
        self.networkManager = networkManager
    }
    
    func fetchWeather(latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error> {
        let endpoint = WeatherEndpoint.currentWeather(lat: latitude, lon: longitude)
        return networkManager.request(endpoint)
    }
}

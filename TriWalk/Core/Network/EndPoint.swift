//
//  EndPoint.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/4/25.
//

import Foundation
import Alamofire

enum APIService {
    case openWeather
    case airKorea
    
    var baseURL: String {
        switch self {
        case .openWeather: return "https://api.openweathermap.org/data/2.5"
        case .airKorea: return "http://apis.data.go.kr/B552584/ArpltnInforInqireSvc"
        }
    }
}

protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders? { get }
    var parameters: Parameters? { get }
    var encoding: ParameterEncoding { get }
}

enum WeatherEndpoint: Endpoint {
    case currentWeather(lat: Double, lon: Double, apiKey: String)
    
    var baseURL: String {
        return APIService.openWeather.baseURL
    }
    
    var path: String {
        switch self {
        case .currentWeather:
            return "/weather"
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var headers: HTTPHeaders? {
        return ["Content-Type": "application/json"]
    }
    
    var parameters: Parameters? {
        switch self {
        case .currentWeather(let lat, let lon, let apiKey):
            return [
                "lat": lat,
                "lon": lon,
                "appid": apiKey,
                "units": "metric",
                "lang": "kr"
            ]
        }
    }
    
    var encoding: ParameterEncoding {
        return URLEncoding.queryString
    }
}

enum AirKoreaEndpoint: Endpoint {
    case dustInfo(stationName: String, apiKey: String)
    
    var baseURL: String {
        return APIService.airKorea.baseURL
    }
    
    var path: String {
        switch self {
        case .dustInfo:
            return "/getMsrstnAcctoRltmMesureDnsty"
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var headers: HTTPHeaders? {
        return ["Content-Type": "application/json"]
    }
    
    var parameters: Parameters? {
        switch self {
        case .dustInfo(let stationName, let apiKey):
            return [
                "stationName": stationName,
                "dataTerm": "DAILY",
                "pageNo": "1",
                "numOfRows": "1",
                "returnType": "json",
                "serviceKey": apiKey
            ]
        }
    }
    
    var encoding: ParameterEncoding {
        return URLEncoding.queryString
    }
}


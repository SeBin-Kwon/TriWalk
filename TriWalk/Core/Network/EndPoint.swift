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
    case kakao
    
    var baseURL: String {
        switch self {
        case .openWeather: return "https://api.openweathermap.org/data/2.5"
        case .airKorea: return "http://apis.data.go.kr/B552584/ArpltnInforInqireSvc"
        case .kakao: return "https://dapi.kakao.com"
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
    case currentWeather(lat: Double, lon: Double)
    
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
        case .currentWeather(let lat, let lon):
            return [
                "lat": lat,
                "lon": lon,
                "appid": APIKey.openWeather,
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
    case dustInfo(stationName: String)
    
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
        case .dustInfo(let stationName):
            return [
                "dataTerm": "DAILY",
                "numOfRows": "1",
                "pageNo": "1",
                "returnType": "json",
                "serviceKey": APIKey.airKorea,
                "stationName": stationName
            ]
        }
    }
    
    var encoding: ParameterEncoding {
        return URLEncoding.queryString
    }
}

enum KakaoEndpoint: Endpoint {
    case coord2address(x: Double, y: Double)
    case searchKeyword(query: String, x: Double, y: Double)
    
    var baseURL: String {
        return APIService.kakao.baseURL
    }
    
    var path: String {
        switch self {
        case .coord2address:
            return "/v2/local/geo/coord2address.json"
        case .searchKeyword:
            return "/v2/local/search/keyword.json"
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var headers: HTTPHeaders? {
        return ["Authorization": "KakaoAK \(APIKey.kakao)"]
    }
    
    var parameters: Parameters? {
        switch self {
        case .coord2address(let x, let y):
            return [
                "x": x,
                "y": y
            ]
        case .searchKeyword(let query, let x, let y):
            return [
                "query": query,
                "x": x,
                "y": y,
                "radius": 2000,
                "sort": "distance"
            ]
        }
    }
    
    var encoding: ParameterEncoding {
        return URLEncoding.queryString
    }
}

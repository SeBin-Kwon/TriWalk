//
//  DestinationSearchViewModel.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/31/25.
//

import Foundation
import Combine
import MapKit
import CoreLocation

class KakaoPlacemark: MKPlacemark {
    var kakaoPlaceName: String
    var kakaoAddress: String
    var kakaoRoadAddress: String
    
    init(coordinate: CLLocationCoordinate2D, placeName: String, address: String, roadAddress: String) {
        self.kakaoPlaceName = placeName
        self.kakaoAddress = address
        self.kakaoRoadAddress = roadAddress
        super.init(coordinate: coordinate)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct SearchResultItem: Hashable {
    let id: String
    let placeName: String
    let address: String
    let roadAddress: String
    let x: Double  // 경도
    let y: Double  // 위도
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SearchResultItem, rhs: SearchResultItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MKPlacemark으로 변환하는 메서드
    func toPlacemark() -> MKPlacemark {
        let coordinate = CLLocationCoordinate2D(latitude: y, longitude: x)
        return KakaoPlacemark(
            coordinate: coordinate,
            placeName: placeName,
            address: address,
            roadAddress: roadAddress
        )
    }
}

final class DestinationSearchViewModel: BaseViewModel, ViewModelType {
    struct Input {
        let searchQuery: AnyPublisher<String, Never>
        let selectItem: AnyPublisher<Int, Never>
    }
    
    struct Output {
        let searchResults: AnyPublisher<[SearchResultItem], Never>
        let isSearching: AnyPublisher<Bool, Never>
        let selectedDestination: AnyPublisher<MKPlacemark?, Never>
    }
    
    private let searchResultsSubject = CurrentValueSubject<[SearchResultItem], Never>([])
    private let isSearchingSubject = CurrentValueSubject<Bool, Never>(false)
    private let selectedDestinationSubject = PassthroughSubject<MKPlacemark?, Never>()
    
    private let kakaoLocationService: KakaoLocationServiceProtocol
    
    init(kakaoLocationService: KakaoLocationServiceProtocol = KakaoLocationService()) {
        self.kakaoLocationService = kakaoLocationService
        super.init()
        //        setupSearchSubscription()
    }
    
    //    private func setupSearchSubscription() {
    //        // 검색 결과 구독
    //        MapManager.shared.searchResultsPublisher
    //            .catch { error -> Empty<[MKMapItem], Never> in
    //                print("검색 오류: \(error.localizedDescription)")
    //                return Empty()
    //            }
    //            .withUnretained(self)
    //            .sink { owner, mapItems in
    //                owner.searchResultsSubject.send(mapItems)
    //            }
    //            .store(in: &cancellables)
    //    }
    
    func transform(input: Input) -> Output {
        // 검색어 입력 처리 - 카카오 API 사용
        input.searchQuery
            .debounce(for: .seconds(0.8), scheduler: RunLoop.main)
            .removeDuplicates()
            .withUnretained(self)
            .sink { owner, query in
                if query.isEmpty {
                    owner.isSearchingSubject.send(false)
                    owner.searchResultsSubject.send([])
                } else {
                    owner.isSearchingSubject.send(true)
                    owner.searchPlaces(query: query)
                }
            }
            .store(in: &cancellables)
        
        // 아이템 선택 처리
        input.selectItem
            .withUnretained(self)
            .sink { owner, index in
                if !owner.isSearchingSubject.value {
                    // "어디든지" 옵션 선택
                    owner.selectedDestinationSubject.send(nil)
                } else if index < owner.searchResultsSubject.value.count {
                    // 검색 결과 선택
                    let selectedItem = owner.searchResultsSubject.value[index]
                    let placemark = selectedItem.toPlacemark()
                    owner.selectedDestinationSubject.send(placemark)
                }
            }
            .store(in: &cancellables)
        
        return Output(
            searchResults: searchResultsSubject.eraseToAnyPublisher(),
            isSearching: isSearchingSubject.eraseToAnyPublisher(),
            selectedDestination: selectedDestinationSubject.eraseToAnyPublisher()
        )
    }
    
    private func searchPlaces(query: String) {
        // 좌표 설정 (현재 위치 또는 기본값)
        let latitude: Double
        let longitude: Double
        
        if let location = LocationManager.shared.currentLocation {
            // 현재 위치가 있는 경우
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            print("현재 위치 기반 검색: 위도 \(latitude), 경도 \(longitude)")
        } else {
            // 현재 위치가 없는 경우 서울 중심부 기본값 사용
            latitude = 37.5665
            longitude = 126.9780
            print("기본 위치 기반 검색: 위도 \(latitude), 경도 \(longitude)")
        }
        
        // 카카오 장소 검색 API 호출
        kakaoLocationService.searchPlaces(query: query, latitude: latitude, longitude: longitude)
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("카카오 장소 검색 오류: \(error.localizedDescription)")
                        self?.searchResultsSubject.send([])
                    }
                },
                receiveValue: { owner, response in
                    // 검색 결과를 SearchResultItem 배열로 변환
                    let items = response.documents.map { doc in
                        SearchResultItem(
                            id: doc.id,
                            placeName: doc.placeName,
                            address: doc.addressName,
                            roadAddress: doc.roadAddressName,
                            x: Double(doc.x) ?? 0.0,
                            y: Double(doc.y) ?? 0.0
                        )
                    }
                    print("검색 결과: \(items.count)개 항목 발견")
                    owner.searchResultsSubject.send(items)
                }
            )
            .store(in: &cancellables)
    }

}

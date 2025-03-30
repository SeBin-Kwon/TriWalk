//
//  DestinationSearchViewModel.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/31/25.
//

import Foundation
import Combine
import MapKit

final class DestinationSearchViewModel: BaseViewModel, ViewModelType {
    struct Input {
        let searchQuery: AnyPublisher<String, Never>
        let selectItem: AnyPublisher<Int, Never>
    }
    
    struct Output {
        let searchResults: AnyPublisher<[MKMapItem], Never>
        let isSearching: AnyPublisher<Bool, Never>
        let selectedDestination: AnyPublisher<MKPlacemark?, Never>
    }
    
    private let searchResultsSubject = CurrentValueSubject<[MKMapItem], Never>([])
    private let isSearchingSubject = CurrentValueSubject<Bool, Never>(false)
    private let selectedDestinationSubject = PassthroughSubject<MKPlacemark?, Never>()
    
    override init() {
        super.init()
        setupSearchSubscription()
    }
    
    private func setupSearchSubscription() {
        // 검색 결과 구독
        MapManager.shared.searchResultsPublisher
            .catch { error -> Empty<[MKMapItem], Never> in
                print("검색 오류: \(error.localizedDescription)")
                return Empty()
            }
            .withUnretained(self)
            .sink { owner, mapItems in
                owner.searchResultsSubject.send(mapItems)
            }
            .store(in: &cancellables)
    }
    
    func transform(input: Input) -> Output {
        // 검색어 입력 처리
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
                    MapManager.shared.searchLocations(query: query)
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
                    owner.selectedDestinationSubject.send(selectedItem.placemark)
                }
            }
            .store(in: &cancellables)
        
        return Output(
            searchResults: searchResultsSubject.eraseToAnyPublisher(),
            isSearching: isSearchingSubject.eraseToAnyPublisher(),
            selectedDestination: selectedDestinationSubject.eraseToAnyPublisher()
        )
    }
}

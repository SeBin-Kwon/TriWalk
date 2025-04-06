//
//  DestinationSearchViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/30/25.
//

import UIKit
import Combine
import MapKit

final class DestinationSearchViewController: BaseViewController {
    weak var delegate: DestinationSearchViewControllerDelegate?
    private let viewModel = DestinationSearchViewModel()
    private let searchTextSubject = PassthroughSubject<String, Never>()
    private let selectItemSubject = PassthroughSubject<Int, Never>()
    
    private var searchResults: [MKMapItem] = []
    private var isSearching = false
    
    // MARK: - UI Components
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "도착지 선택"
        view.backgroundColor = Color.background
        
        // 검색바 설정
        searchBar.placeholder = "장소, 주소 검색"
        searchBar.delegate = self
        
        // 테이블 뷰 설정
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
        
        view.addSubviews(searchBar, tableView)
        
        searchBar.snp.makeConstraints { make in
            make.top.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
    override func bindViewModel() {
        // Input 정의
        let input = DestinationSearchViewModel.Input(
            searchQuery: searchTextSubject.eraseToAnyPublisher(),
            selectItem: selectItemSubject.eraseToAnyPublisher()
        )
        
        // ViewModel 변환
        let output = viewModel.transform(input: input)
        
        // Output 바인딩
        output.searchResults
            .withUnretained(self)
            .sink { owner, results in
                owner.searchResults = results
                owner.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        output.isSearching
            .withUnretained(self)
            .sink { owner, isSearching in
                owner.isSearching = isSearching
                owner.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        output.selectedDestination
            .withUnretained(self)
            .sink { owner, placemark in
                if let placemark = placemark {
                    owner.delegate?.didSelectDestination(placemark)
                } else {
                    owner.delegate?.didSelectAnywhereDestination()
                }
                owner.dismiss(animated: true)
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension DestinationSearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? searchResults.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath)
        
        var config = cell.defaultContentConfiguration()
        
        if !isSearching {
            // "어디든지" 옵션
            config.text = "어디든지"
            config.secondaryText = "목적지 없이 산책하기"
            config.image = UIImage(systemName: "map")?
                .withTintColor(Color.darkContent, renderingMode: .alwaysOriginal)
        } else {
            // 검색 결과
            let mapItem = searchResults[indexPath.row]
            config.text = mapItem.name
            
            let address = [
                mapItem.placemark.thoroughfare,
                mapItem.placemark.locality,
                mapItem.placemark.administrativeArea
            ].compactMap { $0 }.joined(separator: ", ")
            
            config.secondaryText = address
            config.image = UIImage(systemName: "mappin.and.ellipse")?
                .withTintColor(Color.darkContent, renderingMode: .alwaysOriginal)
        }
        
        cell.contentConfiguration = config
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectItemSubject.send(indexPath.row)
    }
}

// MARK: - UISearchBarDelegate
extension DestinationSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTextSubject.send(searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - 도착지 검색 뷰 컨트롤러 델리게이트
protocol DestinationSearchViewControllerDelegate: AnyObject {
    func didSelectDestination(_ placemark: MKPlacemark)
    func didSelectAnywhereDestination()
}

//
//  HomeViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/28/25.
//

import UIKit
import Combine
import SnapKit

enum CardType {
    case weather
    case walkRecord
}

struct CardItem: Hashable {
    let id = UUID()
    // 공통 필드
    let cardType: CardType
    
    // 날씨 카드용 필드
    let weatherData: WeatherCardData?
    
    // 산책 기록 카드용 필드
    let walkRecord: WalkRecord?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CardItem, rhs: CardItem) -> Bool {
        return lhs.id == rhs.id
    }
}

class HomeViewController: BaseViewController {
    weak var delegate: HomeViewControllerDelegate?
    private var dataSource: UICollectionViewDiffableDataSource<Int, CardItem>?
    private var cardItems: [CardItem] = []
    private let homeViewModel = HomeViewModel()
    private let viewDidAppearSubject = PassthroughSubject<Void, Never>()
    private let reloadTriggerSubject = PassthroughSubject<Void, Never>()
    private var historyCards: [CardItem] = [] // 산책 기록 카드만 따로 관리
    private var weatherCard: CardItem? // 날씨 카드를 별도로 관리
    static let sectionIdentifier = 0
    
    let titleLabel = {
        let label = UILabel()
        label.text = "오늘은 산책 여행 하기\n딱 좋은 날씨!"
        label.applyHeading1Style()
        return label
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            HomeViewController.createLayout()
        }
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    
    let startButton = ConfigButton(title: "산책 여행 떠나기")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupCollectionView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearSubject.send(())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 뷰가 다시 나타날 때마다 날씨 카드가 마지막에 오도록 데이터 재정렬
        reorganizeCards()
        updateSnapshot(animated: false)
    }
    
    private func reorganizeCards() {
            // 배열 재구성 - 히스토리 카드 먼저, 날씨 카드는 마지막에
        cardItems = historyCards
        if let weather = weatherCard {
            cardItems.append(weather)
        }
    }
    
    override func bindViewModel() {
        startButton.controlPublisher(for: .touchUpInside)
            .withUnretained(self)
            .sink { owner, _ in
                owner.delegate?.didTapStartButton()
            }
            .store(in: &cancellables)
        
        // 날씨 뷰모델 바인딩
        let input = HomeViewModel.Input(
            viewDidAppear: viewDidAppearSubject.eraseToAnyPublisher(),
            reloadTrigger: reloadTriggerSubject.eraseToAnyPublisher()
        )
        
        let output = homeViewModel.transform(input: input)
        
        // 날씨 데이터 수신
        output.weatherData
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, weatherData in
                // 기존 날씨 카드 찾아 업데이트하거나 새로 추가
                if let index = owner.cardItems.firstIndex(where: { $0.cardType == .weather }) {
                    var newItems = owner.cardItems
                    newItems[index] = CardItem(
                        cardType: .weather,
                        weatherData: weatherData,
                        walkRecord: nil
                    )
                    owner.cardItems = newItems
                } else {
                    owner.cardItems.append(
                        CardItem(
                            cardType: .weather,
                            weatherData: weatherData,
                            walkRecord: nil
                        )
                    )
                }
                
                owner.updateSnapshot()
            }
            .store(in: &cancellables)
        
        output.walkRecords
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, walkRecords in
                print("산책 기록 수신: \(walkRecords.count)개")
                
                // 기존 산책 기록 카드 제거
                owner.cardItems.removeAll { $0.cardType == .walkRecord }
                
                // 새로운 산책 기록 카드 추가
                for record in walkRecords {
                    owner.cardItems.append(CardItem(
                        cardType: .walkRecord,
                        weatherData: nil,
                        walkRecord: record
                    ))
                }
                
                owner.updateSnapshot()
            }
            .store(in: &cancellables)
        
        // 에러 처리
        output.error
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, errorMessage in
                print("날씨 데이터 로드 실패: \(errorMessage)")
                // 에러 처리 UI (필요시 알림창 등 표시)
            }
            .store(in: &cancellables)
    }

    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.register(WeatherCardCell.self, forCellWithReuseIdentifier: WeatherCardCell.identifier)
        collectionView.register(TicketCardCell.self, forCellWithReuseIdentifier: TicketCardCell.identifier)
        configureDataSource()
    }
    
    private func setupNavigationBar() {
        let chartButton = UIBarButtonItem(image: UIImage(symbol: .calendar), style: .plain, target: self, action: #selector(calendarButtonTap))
        navigationItem.rightBarButtonItem = chartButton
    }
    
    @objc private func calendarButtonTap() {
        print("calendar")
    }
    
    override func configureHierarchy() {
        view.addSubviews(titleLabel, startButton, collectionView)
    }
    
    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalTo(view.safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
        
        collectionView.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(480)
        }
        
        startButton.snp.makeConstraints { make in
            make.bottom.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
    }
    
    override func configureView() {
        startButton.applyHomeButtonStyle()
    }
    
    private func convertToWeatherCardData(from item: CardItem) -> WeatherCardData? {
            return item.weatherData
        }
    
    private func convertToWalkCompletedData(from walkRecord: WalkRecord) -> WalkCompletedData {
            return FormatManager.shared.formatWalkRecordToCompletedData(walkRecord)
        }

}

extension HomeViewController: UICollectionViewDelegate {
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, CardItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item.cardType {
            case .weather:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: WeatherCardCell.identifier, for: indexPath ) as? WeatherCardCell else { return UICollectionViewCell() }
                if let weatherData = item.weatherData {
                    cell.configure(with: weatherData)
                }
                return cell
                
            case .walkRecord:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: TicketCardCell.identifier, for: indexPath) as? TicketCardCell, let walkRecord = item.walkRecord else { return UICollectionViewCell() }
                
                let walkData = self.convertToWalkCompletedData(from: walkRecord)
                cell.configure(with: walkData)
                return cell
            }
        }
        
        updateSnapshot(animated: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource?.itemIdentifier(for: indexPath) else { return }
        if item.cardType == .walkRecord, let walkRecord = item.walkRecord {
            print("산책 기록 선택: \(walkRecord.id)")
            // 예: let detailVC = WalkDetailViewController(walkRecord: walkRecord)
            // navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    private func updateSnapshot(animated: Bool = true) {
        guard let dataSource = dataSource else { return }
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, CardItem>()
        snapshot.appendSections([HomeViewController.sectionIdentifier])
        snapshot.appendItems(cardItems, toSection: HomeViewController.sectionIdentifier)
//        dataSource.apply(snapshot, animatingDifferences: animated)
        dataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            self?.scrollToLastItem(animated: false)
        }
    }
    
    // 마지막 아이템으로 스크롤
    private func scrollToLastItem(animated: Bool = false) {
        guard !cardItems.isEmpty else { return }
            
            let lastIndex = cardItems.count - 1
            let indexPath = IndexPath(item: lastIndex, section: HomeViewController.sectionIdentifier)
            
            DispatchQueue.main.async { [weak self] in
                // 스냅 효과를 위해 스크롤 방식 변경
                self?.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
    
    static func createLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.8),
                                               heightDimension: .absolute(450))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        section.interGroupSpacing = 12
        
        section.visibleItemsInvalidationHandler = { (items, offset, environment) in
            items.forEach { item in
                // 아이템 중앙에 가까울수록 크기와 불투명도 조정
                let distanceFromCenter = abs((item.frame.midX - offset.x) - environment.container.contentSize.width / 2.0)
                let minScale: CGFloat = 0.9
                let maxScale: CGFloat = 1.0
                let scale = max(maxScale - (distanceFromCenter / environment.container.contentSize.width) * 0.5, minScale)
                item.transform = CGAffineTransform(scaleX: scale, y: scale)
                
                // 선택적: 중앙에서 멀어질수록 투명해지는 효과
                let minAlpha: CGFloat = 0.7
                let maxAlpha: CGFloat = 1.0
                let alpha = max(maxAlpha - (distanceFromCenter / environment.container.contentSize.width) * 0.7, minAlpha)
                item.alpha = alpha
            }
        }
        
        return section
    }
}

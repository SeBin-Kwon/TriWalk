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
    case history
    case today
}

enum WeatherType {
    case sunny
    case rainy
    case clear
    
    var description: String {
        switch self {
        case .sunny:
            return "좋음"
        case .rainy:
            return "나쁨"
        case .clear:
            return "보통"
        }
    }
    
    var color: UIColor {
        switch self {
        case .sunny:
            return .systemGreen
        case .rainy:
            return .systemRed
        case .clear:
            return .systemBlue
        }
    }
}

struct CardItem: Hashable {
    let id = UUID()
    let date: String
    let temperature: Int
    let weatherType: WeatherType
    let cardType: CardType
    
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
    private var weatherCards: [CardItem] = []
    
    // 상수 추가
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
    
    override func bindViewModel() {
        startButton.controlPublisher(for: .touchUpInside)
            .withUnretained(self)
            .sink { owner, _ in
                owner.delegate?.didTapStartButton()
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
}

extension HomeViewController: UICollectionViewDelegate {
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, CardItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item.cardType {
            case .today:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: WeatherCardCell.identifier, for: indexPath ) as? WeatherCardCell else { return UICollectionViewCell() }
                cell.configure(with: item)
                return cell
                
            case .history:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: TicketCardCell.identifier, for: indexPath) as? TicketCardCell else { return UICollectionViewCell() }
                
                // 산책 데이터로 변환하여 TicketView에 전달
                let walkData = WalkCompletedData(
                    date: item.date,
                    weekday: "WED", // 실제 구현 시에는 날짜에서 요일 추출
                    startLocation: "BJK",
                    startTime: "04:26 PM",
                    endLocation: "OPS",
                    endTime: "05:38 PM",
                    steps: 426,
                    distance: 1.3,
                    calories: 122,
                    duration: "01:12:48"
                )
                
                cell.configure(with: walkData)
                return cell
            }
        }
        
        // 초기 데이터 생성 및 적용
        weatherCards = [
            CardItem(date: "3.25 TUE", temperature: 26, weatherType: .sunny, cardType: .history),
            CardItem(date: "3.25 TUE", temperature: 26, weatherType: .rainy, cardType: .history),
            CardItem(date: "3.26 WED", temperature: 26, weatherType: .clear, cardType: .today)
        ]
        
        updateSnapshot(animated: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("HomeCellTapped")
    }
    
    private func updateSnapshot(animated: Bool = true) {
        guard let dataSource = dataSource else { return }
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, CardItem>()
        snapshot.appendSections([HomeViewController.sectionIdentifier])
        snapshot.appendItems(weatherCards, toSection: HomeViewController.sectionIdentifier)
        
        dataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            self?.scrollToLastItem()
        }
    }
    
    // 마지막 아이템으로 스크롤
    private func scrollToLastItem() {
        guard !weatherCards.isEmpty else { return }
        
        let lastIndex = weatherCards.count - 1
        let indexPath = IndexPath(item: lastIndex, section: HomeViewController.sectionIdentifier)
        
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
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
        
        return section
    }
}

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
    private var selectedCardIndex: Int?
    
    private var lastPopTime: Date?
    private let popScrollThreshold: TimeInterval = 1.0
    private var currentTitleMessage: String?
    
    let titleLabel = {
        let label = UILabel()
        label.text = "날씨 정보 가져오는 중..."
        label.applyHeading1Style(color: .darkContent)
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
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let image = UIImage(systemName: "chevron.down.2", withConfiguration: config)
        imageView.image = image
        imageView.tintColor = .textSecondary
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0.7
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupCollectionView()
        NotificationCenterManager.locationPermissionGranted.publisher()
            .withUnretained(self)
                .sink { owner, _ in
                    owner.viewDidAppearSubject.send(())  // 권한 획득 시 데이터 새로고침
                }
                .store(in: &cancellables)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearSubject.send(())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if weatherCard == nil {
            titleLabel.text = "날씨 정보 가져오는 중..."
            currentTitleMessage = nil
        }
        reorganizeCards()
                
        // 이전에 선택된 카드가 있고 최근에 pop된 경우 스크롤 애니메이션 없이 해당 카드로 이동
        let shouldScrollWithoutAnimation = isRecentlyPopped()
        updateSnapshot(animated: !shouldScrollWithoutAnimation)
        
        // 선택된 카드가 있으면 스크롤
        if let index = selectedCardIndex, shouldScrollWithoutAnimation {
            scrollToCard(at: index, animated: false)
        }
    }
    
    private func isRecentlyPopped() -> Bool {
        guard let lastPopTime = lastPopTime else { return false }
        return Date().timeIntervalSince(lastPopTime) < popScrollThreshold
    }
    
    // pop 시간 기록 메서드 - UINavigationControllerDelegate에서 호출
    func recordPopTime() {
        lastPopTime = Date()
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
                owner.animateWeatherMessage(weatherData.message)
                let newWeatherCard = CardItem(
                    cardType: .weather,
                    weatherData: weatherData,
                    walkRecord: nil
                )
                
                // 변경사항이 있는 경우만 업데이트
                if owner.weatherCard?.weatherData?.temperature != weatherData.temperature ||
                   owner.weatherCard?.weatherData?.dustGrade != weatherData.dustGrade {
                    owner.weatherCard = newWeatherCard
                    owner.reorganizeCards()
                    owner.updateSnapshot()
                } else if owner.weatherCard == nil {
                    owner.weatherCard = newWeatherCard
                    owner.reorganizeCards()
                    owner.updateSnapshot()
                }
            }
            .store(in: &cancellables)
        
        output.walkRecords
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, walkRecords in
                print("산책 기록 수신: \(walkRecords.count)개")
                let newHistoryCards = walkRecords.map { record in
                    CardItem(
                        cardType: .walkRecord,
                        weatherData: nil,
                        walkRecord: record
                    )
                }
                owner.historyCards = newHistoryCards
                owner.reorganizeCards()
                owner.updateSnapshot()
            }
            .store(in: &cancellables)
        
        // 에러 처리
        output.error
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, errorMessage in
                owner.titleLabel.text = "날씨 정보를 가져오지\n못했어요 :("
                print("날씨 데이터 로드 실패: \(errorMessage)")
                // 에러 처리 UI (필요시 알림창 등 표시)
            }
            .store(in: &cancellables)
        
        output.isDelete
            .withUnretained(self)
            .sink { owner, _ in
                ToastView.showSuccess(in: owner, message: "산책 기록을 삭제했습니다.")
            }
            .store(in: &cancellables)
    }
    
    // 산책 히스토리 카드 비교 (기록 ID 기반)
        private func areHistoryCardsEqual(_ old: [CardItem], _ new: [CardItem]) -> Bool {
            guard old.count == new.count else { return false }
            
            for i in 0..<old.count {
                if old[i].walkRecord?.id != new[i].walkRecord?.id {
                    return false
                }
            }
            return true
        }
    
    private func animateWeatherMessage(_ message: String) {
        if message == currentTitleMessage && titleLabel.alpha == 1 {
            return
        }
        
        // 새로운 메시지 저장
        currentTitleMessage = message
        
        // 애니메이션 전 초기 상태 설정
        titleLabel.alpha = 0
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 20)
        
        // 텍스트 설정
        titleLabel.text = message
        
        // 애니메이션 실행
        UIView.animate(withDuration: 0.7, delay: 0.1,
                      usingSpringWithDamping: 0.7,
                      initialSpringVelocity: 0.5,
                      options: [], animations: {
            self.titleLabel.alpha = 1
            self.titleLabel.transform = .identity
        }, completion: nil)
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
        let vc = CalendarViewController(viewModel: CalendarViewModel())
        navigate(.push(vc))
    }
    
    override func configureHierarchy() {
        view.addSubviews(titleLabel, startButton, collectionView, arrowImageView)
    }
    
    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalTo(view.safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
        
//        collectionView.backgroundColor = .red
        
        collectionView.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(500)
        }
        
        startButton.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(Spacing.screenMargin)
            make.bottom.equalTo(arrowImageView.snp.top).offset(-Spacing.s)
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.top.equalTo(startButton.snp.bottom)
            make.centerX.equalToSuperview()
            make.width.equalTo(35)
            make.height.equalTo(25)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
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
            // 선택된 카드 인덱스 저장
            selectedCardIndex = indexPath.item
            
            // 상세 화면으로 이동
            let detailVC = WalkDetailViewController(walkId: walkRecord.id)
            navigate(.push(detailVC))
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            updateVisibleCardIndex()
        }
        
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateVisibleCardIndex()
    }
    
    private func updateVisibleCardIndex() {
        let center = CGPoint(x: collectionView.contentOffset.x + collectionView.bounds.width / 2,
                           y: collectionView.bounds.height / 2)
        
        if let indexPath = collectionView.indexPathForItem(at: center) {
            // 현재 보이는 카드의 인덱스 저장
            selectedCardIndex = indexPath.item
        }
    }
    
    private func updateSnapshot(animated: Bool = true) {
        guard let dataSource = dataSource else { return }
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, CardItem>()
        snapshot.appendSections([HomeViewController.sectionIdentifier])
        let validCardItems = cardItems.filter { item in
            if let walkRecord = item.walkRecord {
                return !walkRecord.isInvalidated
            }
            return true
        }
        snapshot.appendItems(validCardItems, toSection: HomeViewController.sectionIdentifier)
        
        // 인터랙션 중 업데이트 방지
        let isInteracting = collectionView.isDragging || collectionView.isDecelerating
        
        dataSource.apply(snapshot, animatingDifferences: animated && !isInteracting) { [weak self] in
            guard let self = self else { return }
            
            // 선택된 카드가 있거나 최근에 pop된 경우가 아니면 마지막 카드로 스크롤 (날씨 카드)
            if self.selectedCardIndex == nil && !self.isRecentlyPopped() && !self.cardItems.isEmpty {
                self.scrollToLastItem(animated: animated)
            }
        }
    }
    
    private func scrollToCard(at index: Int, animated: Bool) {
            guard index >= 0 && index < cardItems.count else { return }
            
            let indexPath = IndexPath(item: index, section: HomeViewController.sectionIdentifier)
            DispatchQueue.main.async { [weak self] in
                self?.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
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
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 16, bottom: 16, trailing: 16)
        section.interGroupSpacing = 12
        
        section.visibleItemsInvalidationHandler = { (items, offset, environment) in
            items.forEach { item in
                // 아이템 중앙에 가까울수록 크기와 불투명도 조정
                let distanceFromCenter = abs((item.frame.midX - offset.x) - environment.container.contentSize.width / 2.0)
                let minScale: CGFloat = 0.9
                let maxScale: CGFloat = 1.0
                let scale = max(maxScale - (distanceFromCenter / environment.container.contentSize.width) * 0.5, minScale)
                item.transform = CGAffineTransform(scaleX: scale, y: scale * 0.99)
                
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

extension HomeViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // 현재 화면이 HomeViewController이고 이전 화면이 있었다면 (pop된 경우)
        if viewController == self && navigationController.viewControllers.count < navigationController.children.count {
            recordPopTime()
        }
    }
}

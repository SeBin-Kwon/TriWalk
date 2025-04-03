//
//  WalkTrackingView.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/31/25.
//

import UIKit
import Combine
import SnapKit

final class WalkTrackingSheetView: BaseView {
    private let formatManager: FormatManagerProtocol
    
    init(formatManager: FormatManagerProtocol = FormatManager.shared) {
        self.formatManager = formatManager
        super.init(frame: .zero)
        setupBindings()
    }
    
    private let metricsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        return stackView
    }()
    
    // 걸음수 관련 뷰
    private let stepsContainerView = UIView()
    private let stepsLabel: UILabel = {
        let label = UILabel()
        label.applyHeading3Style()
        label.textAlignment = .center
        label.text = "0"
        return label
    }()
    
    private let stepsTitleLabel: UILabel = {
        let label = UILabel()
        label.applyBodySmallStyle(color: .textSecondary)
        label.textAlignment = .center
        label.text = "걸음수"
        return label
    }()
    
    // 거리 관련 뷰
    private let distanceContainerView = UIView()
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.applyHeading3Style()
        label.textAlignment = .center
        label.text = "0.0"
        return label
    }()
    
    private let distanceUnitLabel: UILabel = {
        let label = UILabel()
        label.applyBodyMediumStyle()
        label.textAlignment = .center
        label.text = "km"
        return label
    }()
    
    private let distanceTitleLabel: UILabel = {
        let label = UILabel()
        label.applyBodySmallStyle(color: .textSecondary)
        label.textAlignment = .center
        label.text = "거리"
        return label
    }()
    
    // 칼로리 관련 뷰
    private let caloriesContainerView = UIView()
    private let caloriesLabel: UILabel = {
        let label = UILabel()
        label.applyHeading3Style()
        label.textAlignment = .center
        label.text = "0"
        return label
    }()
    
    private let caloriesUnitLabel: UILabel = {
        let label = UILabel()
        label.applyBodyMediumStyle()
        label.textAlignment = .center
        label.text = "kcal"
        return label
    }()
    
    private let caloriesTitleLabel: UILabel = {
        let label = UILabel()
        label.applyBodySmallStyle(color: .textSecondary)
        label.textAlignment = .center
        label.text = "칼로리"
        return label
    }()
    
    // 시간 관련 뷰
    private let timeContainerView = UIView()
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.applyHeading2Style()
        label.textAlignment = .center
        label.text = "00:00:00"
        return label
    }()
    
    private let timeTitleLabel: UILabel = {
        let label = UILabel()
        label.applyBodySmallStyle(color: .textSecondary)
        label.textAlignment = .center
        label.text = "소요시간"
        return label
    }()
    
    // 갤러리 영역
    private let galleryContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let galleryTitleLabel: UILabel = {
        let label = UILabel()
        label.font = Font.bodyMedium
        label.textColor = .contentPrimary
        label.text = "갤러리"
        return label
    }()
    
    private let galleryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.minimumLineSpacing = 8
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
        return collectionView
    }()
    
    let addPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemGray5
        button.tintColor = .contentPrimary
        button.layer.cornerRadius = 8
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        return button
    }()

    let pauseButton: ConfigButton = {
        let button = ConfigButton(title: "일시정지")
        button.setBackgroundColor(.contentPrimary)
        button.setTextColor(.white)
        button.setCornerRadius(12)
        return button
    }()
    
    let finishButton: ConfigButton = {
        let button = ConfigButton(title: "여행 종료")
        button.setBackgroundColor(.triWalkPrimary)
        button.setCornerRadius(12)
        return button
    }()
    
// MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    
    // Input/Output 정의
    private let stepsSubject = PassthroughSubject<Int, Never>()
    private let distanceSubject = PassthroughSubject<Double, Never>()
    private let caloriesSubject = PassthroughSubject<Double, Never>()
    private let timeSubject = PassthroughSubject<TimeInterval, Never>()
    private let pauseButtonTappedSubject = PassthroughSubject<Void, Never>()
    private let finishButtonTappedSubject = PassthroughSubject<Void, Never>()
    private let addPhotoButtonTappedSubject = PassthroughSubject<Void, Never>()
    
    var stepsPublisher: AnyPublisher<Int, Never> {
        return stepsSubject.eraseToAnyPublisher()
    }
    
    var distancePublisher: AnyPublisher<Double, Never> {
        return distanceSubject.eraseToAnyPublisher()
    }
    
    var caloriesPublisher: AnyPublisher<Double, Never> {
        return caloriesSubject.eraseToAnyPublisher()
    }
    
    var timePublisher: AnyPublisher<TimeInterval, Never> {
        return timeSubject.eraseToAnyPublisher()
    }
    
    var pauseButtonTappedPublisher: AnyPublisher<Void, Never> {
        return pauseButtonTappedSubject.eraseToAnyPublisher()
    }
    
    var finishButtonTappedPublisher: AnyPublisher<Void, Never> {
        return finishButtonTappedSubject.eraseToAnyPublisher()
    }
    
    var addPhotoButtonTappedPublisher: AnyPublisher<Void, Never> {
        return addPhotoButtonTappedSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Setup
    override func configureHierarchy() {
        // 메인 컴포넌트 추가
        addSubviews(metricsStackView, timeContainerView, galleryContainerView, pauseButton, finishButton)
        
        // 메트릭 스택뷰에 항목 추가
        metricsStackView.addArrangedSubview(stepsContainerView)
        metricsStackView.addArrangedSubview(distanceContainerView)
        metricsStackView.addArrangedSubview(caloriesContainerView)
        
        // 걸음수 컨테이너 설정
        stepsContainerView.addSubviews(stepsLabel, stepsTitleLabel)
        
        // 거리 컨테이너 설정
        distanceContainerView.addSubviews(distanceLabel, distanceUnitLabel, distanceTitleLabel)
        
        // 칼로리 컨테이너 설정
        caloriesContainerView.addSubviews(caloriesLabel, caloriesUnitLabel, caloriesTitleLabel)
        
        // 시간 컨테이너 설정
        timeContainerView.addSubviews(timeLabel, timeTitleLabel)
        
        // 갤러리 컨테이너 설정
        galleryContainerView.addSubviews(galleryTitleLabel, galleryCollectionView, addPhotoButton)
    }
    
    override func configureLayout() {
        
        // 메트릭 스택뷰
        metricsStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(70).priority(.high)
        }
        
        // 걸음수 레이블들
        stepsLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        stepsTitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(stepsLabel.snp.bottom).offset(4)
        }
        
        // 거리 레이블들
        distanceLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-10)
            make.top.equalToSuperview()
        }
        
        distanceUnitLabel.snp.makeConstraints { make in
            make.leading.equalTo(distanceLabel.snp.trailing).offset(4)
            make.centerY.equalTo(distanceLabel)
        }
        
        distanceTitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(distanceLabel.snp.bottom).offset(4)
        }
        
        // 칼로리 레이블들
        caloriesLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-15)
            make.top.equalToSuperview()
        }
        
        caloriesUnitLabel.snp.makeConstraints { make in
            make.leading.equalTo(caloriesLabel.snp.trailing).offset(4)
            make.centerY.equalTo(caloriesLabel)
        }
        
        caloriesTitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(caloriesLabel.snp.bottom).offset(4)
        }
        
        // 시간 컨테이너
        timeContainerView.snp.makeConstraints { make in
            make.top.equalTo(metricsStackView.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(80)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(15)
        }
        
        timeTitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(timeLabel.snp.bottom).offset(4)
        }
        
        // 갤러리 컨테이너
        galleryContainerView.snp.makeConstraints { make in
            make.top.equalTo(timeContainerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(130)
        }
        
        galleryTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
        }
        
        addPhotoButton.snp.makeConstraints { make in
            make.centerY.equalTo(galleryTitleLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(28)
        }
        
        galleryCollectionView.snp.makeConstraints { make in
            make.top.equalTo(galleryTitleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        
        // 버튼들
        pauseButton.snp.makeConstraints { make in
            make.top.equalTo(galleryContainerView.snp.bottom).offset(16).priority(.medium)
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-30).priority(.high)
            make.width.equalTo((UIScreen.main.bounds.width - (16 * 3)) / 2)
            make.height.equalTo(55)
        }
        
        finishButton.snp.makeConstraints { make in
            make.top.equalTo(pauseButton)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(pauseButton)
            make.width.equalTo(pauseButton)
        }
    }
    
    override func configureView() {
        backgroundColor = .background
        layer.cornerRadius = 30
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        clipsToBounds = true
    }
    
    private func setupBindings() {
            pauseButton.controlPublisher(for: .touchUpInside)
                .withUnretained(self)
                .sink { onwer, _ in
                    onwer.pauseButtonTappedSubject.send()
                }
                .store(in: &cancellables)
            
            finishButton.controlPublisher(for: .touchUpInside)
                .withUnretained(self)
                .sink { onwer, _ in
                    onwer.finishButtonTappedSubject.send()
                }
                .store(in: &cancellables)
            
            addPhotoButton.controlPublisher(for: .touchUpInside)
                .withUnretained(self)
                .sink { onwer, _ in
                    onwer.addPhotoButtonTappedSubject.send()
                }
                .store(in: &cancellables)
        }
    
    // MARK: - Public Methods
    
    /// 걸음수 업데이트
    func updateSteps(_ steps: Int) {
        stepsLabel.text = "\(steps)"
    }
    
    /// 거리 업데이트
    func updateDistance(_ distance: Double) {
        distanceLabel.text = String(format: "%.1f", distance)
    }
    
    /// 칼로리 업데이트
    func updateCalories(_ calories: Double) {
        caloriesLabel.text = "\(Int(calories))"
    }
    
    /// 시간 업데이트
    func updateTime(_ timeInterval: TimeInterval) {
        timeLabel.text = formatManager.formattedDuration(seconds: timeInterval)
    }
    
    /// 일시정지/재개 버튼 상태 업데이트
    func updatePauseButton(isPaused: Bool) {
        pauseButton.setTitle(isPaused ? "계속하기" : "일시정지", for: .normal)
    }
    
    /// 사진 추가
    func addPhoto(_ image: UIImage) {
        galleryCollectionView.reloadData()
    }
    
    func fadeOutContentForMinimize() {
        // 손잡이를 제외한 모든 요소 숨기기
        [metricsStackView, timeContainerView, galleryContainerView, pauseButton, finishButton].forEach {
            $0.alpha = 0
            $0.isHidden = true
        }
    }

    // 시트가 최대화될 때 컨텐츠 페이드 인
    func fadeInContentAfterMaximize() {
        // 모든 요소 다시 표시
        [metricsStackView, timeContainerView, galleryContainerView, pauseButton, finishButton].forEach {
            $0.alpha = 1
            $0.isHidden = false
        }
    }
}

// MARK: - 갤러리 셀
class PhotoCell: UICollectionViewCell {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with image: UIImage) {
        imageView.image = image
    }
}

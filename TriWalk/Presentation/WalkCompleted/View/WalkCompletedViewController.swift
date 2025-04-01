//
//  WalkCompletedViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/1/25.
//

import UIKit
import Combine

final class WalkCompletedViewController: BaseViewController {
    
    // MARK: - Properties
    weak var delegate: WalkCompletedViewControllerDelegate?
    private let walkCompletedView = WalkCompletedView()
    
    // 산책 데이터
    private var walkData: WalkCompletedData?
    
    // MARK: - Lifecycle
    override func loadView() {
        view = walkCompletedView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 샘플 데이터 설정 - 실제로는 ViewModel이나 파라미터로 전달받아야 함
        setupSampleData()
        
        // 이미지 설정
        setupImages()
    }
    
    // MARK: - Setup
    override func bindViewModel() {
        // 홈으로 버튼 탭 이벤트 바인딩
        walkCompletedView.homeButton.controlPublisher(for: .touchUpInside)
            .withUnretained(self)
            .sink { owner, _ in
                let vc = MainContainerViewController()
                owner.changeRootViewController(rootView: vc)
            }
            .store(in: &cancellables)
    }
    
    private func setupSampleData() {
        // 샘플 데이터 - 실제 구현 시에는 이전 화면에서 전달받은 데이터 사용
        let data = WalkCompletedData(
            date: "2025.03.26",
            weekday: "WED",
            startLocation: "BJK",
            startTime: "04:26 PM",
            endLocation: "OPS",
            endTime: "05:38 PM",
            steps: 426,
            distance: 1.3,
            calories: 122,
            duration: "01:12:48"
        )
        
        walkData = data
        walkCompletedView.configure(with: data)
    }
    
    private func setupImages() {
        // 화살표 이미지 설정
        // 나중에 실제 이미지로 대체
        let arrowImage = UIImage(systemName: "arrow.right")?.withTintColor(.textSecondary, renderingMode: .alwaysOriginal)
        walkCompletedView.setArrowImage(arrowImage)
        
        // 로고 이미지 설정
        // 나중에 실제 이미지로 대체
        let logoImage = createPlaceholderLogo()
        walkCompletedView.setLogoImage(logoImage)
    }
    
    // 임시 로고 생성 (실제 구현에서는 에셋에서 로드해야 함)
    private func createPlaceholderLogo() -> UIImage? {
        let size = CGSize(width: 120, height: 40)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // 로고 배경 설정 (투명)
            UIColor.clear.setFill()
            context.fill(rect)
            
            // 로고 텍스트 설정
            let text = "TriWalk"
            let font = UIFont.systemFont(ofSize: 22, weight: .bold)
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: Color.primary
            ]
            
            let textSize = text.size(withAttributes: textAttributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: textAttributes)
        }
    }
    
    // MARK: - Public Methods
    /// 산책 완료 데이터 설정
    func configure(with data: WalkCompletedData) {
        walkData = data
        
        // 뷰가 로드된 경우에만 설정
        if isViewLoaded {
            walkCompletedView.configure(with: data)
        }
    }
}


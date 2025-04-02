//
//  WalkCompletedViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/1/25.
//

import UIKit
import Combine

final class WalkCompletedViewController: BaseViewController {
    
    private let walkCompletedView = WalkCompletedView()
    
    // 산책 데이터
    private var walkData: WalkCompletedData?
    private let viewModel: WalkCompletedViewModel
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    
    init(walkRecord: WalkRecord? = nil, formatManager: FormatManagerProtocol = FormatManager.shared) {
        self.viewModel = WalkCompletedViewModel(walkRecord: walkRecord, formatManager: formatManager)
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Lifecycle
    override func loadView() {
        view = walkCompletedView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 이미지 설정
        setupImages()
        viewDidLoadSubject.send(())
    }
    
    // MARK: - Setup
    override func bindViewModel() {
        let input = WalkCompletedViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            homeButtonTapped: walkCompletedView.homeButton.controlPublisher(for: .touchUpInside)
                .map { _ in () }
                .eraseToAnyPublisher()
        )
        
        // ViewModel 변환
        let output = viewModel.transform(input: input)
        
        output.walkCompletedData
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, data in
                owner.walkCompletedView.configure(with: data)
            }
            .store(in: &cancellables)
        
        // 화면 닫기
        output.dismissView
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, _ in
                let vc = MainContainerViewController()
                owner.changeRootViewController(rootView: vc)
            }
            .store(in: &cancellables)
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
}


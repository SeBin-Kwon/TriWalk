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
}


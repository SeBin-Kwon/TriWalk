//
//  WalkSetupViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/28/25.
//

import UIKit
import Combine
import SnapKit

class WalkSetupViewController: BaseViewController {
    weak var delegate: WalkSetupViewControllerDelegate?
    
    let titleLabel = {
        let label = UILabel()
        label.text = "어디로 떠날까요?"
        label.applyHeading1Style()
        return label
    }()
    
    let startButton = ConfigButton(title: "산책 여행 떠나기!")

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func bindViewModel() {
        startButton.controlPublisher(for: .touchUpInside)
            .withUnretained(self)
            .sink { owner, _ in
                let vc = WalkSetupViewController()
                owner.navigate(.push(vc))
            }
            .store(in: &cancellables)
    }
    
    override func configureHierarchy() {
        view.addSubviews(titleLabel, startButton)
    }
    
    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalTo(view.safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
        
        startButton.snp.makeConstraints { make in
            make.bottom.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
    }

}

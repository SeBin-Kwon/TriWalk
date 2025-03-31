//
//  WalkCompletedViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/1/25.
//

import UIKit

class WalkCompletedViewController: UIViewController {
    weak var delegate: WalkCompletedViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        
        // UI 요소 설정
        let titleLabel = UILabel()
        titleLabel.text = "상세 화면"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        // 스와이프 안내 레이블
        let instructionLabel = UILabel()
        instructionLabel.text = "아래로 스와이프하여 홈 페이지로 돌아가기"
        instructionLabel.font = .systemFont(ofSize: 16)
        instructionLabel.textAlignment = .center
        instructionLabel.textColor = .systemGray
        
        view.addSubview(instructionLabel)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])
    }
}


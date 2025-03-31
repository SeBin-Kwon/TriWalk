//
//  WalkTrackingSheetViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/31/25.
//

import UIKit
import Combine

protocol WalkTrackingSheetViewControllerDelegate: AnyObject {
    func didTapPauseButton(isPaused: Bool)
    func didTapFinishButton()
    func didTapAddPhotoButton()
}

final class WalkTrackingSheetViewController: BaseViewController {
    // MARK: - Properties
    let walkTrackingView = WalkTrackingSheetView()
    weak var delegate: WalkTrackingSheetViewControllerDelegate?
    
    // 트래킹 상태
    private var isPaused = false
    
    // MARK: - Lifecycle
    override func loadView() {
        view = walkTrackingView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isModalInPresentation = true
        setupSheet()
        setupActions()
    }
    
    // MARK: - Setup
    private func setupSheet() {
        // 시트 프레젠테이션 컨트롤러의 델리게이트 설정
        sheetPresentationController?.delegate = self
        
        // 시트 설정
        if let sheet = sheetPresentationController {
            if #available(iOS 16.0, *) {
                // 커스텀 identifier 생성
                let minimizedId = UISheetPresentationController.Detent.Identifier("minimized")
                let normalId = UISheetPresentationController.Detent.Identifier("normal")
                
                // detent 설정
                sheet.detents = [
                    .custom(identifier: minimizedId) { _ in return 60 },   // 최소 높이
                    .custom(identifier: normalId) { _ in return 300 }      // 일반 높이
                ]
                
                // 배경 딤 처리 안할 최대 높이 설정
                sheet.largestUndimmedDetentIdentifier = normalId
                
                // 디폴트로 표시할 높이 설정
                sheet.selectedDetentIdentifier = normalId
            } else {
                // iOS 15에서는 custom detent를 사용할 수 없으므로 medium 높이를 최소로 설정
                sheet.detents = [.medium()]
            }
            
            sheet.prefersGrabberVisible = true
            
            // 🔵 시트 동작 설정 - 완전히 닫히지 않도록 설정
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.preferredCornerRadius = 20
        }
    }
    
    private func setupActions() {
        // 일시정지/재개 버튼 액션
        walkTrackingView.pauseButton.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
        
        // 종료 버튼 액션
        walkTrackingView.finishButton.addTarget(self, action: #selector(finishButtonTapped), for: .touchUpInside)
        
        // 사진 추가 버튼 액션
        walkTrackingView.addPhotoButton.addTarget(self, action: #selector(addPhotoButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func pauseButtonTapped() {
        isPaused.toggle()
        walkTrackingView.updatePauseButton(isPaused: isPaused)
        delegate?.didTapPauseButton(isPaused: isPaused)
    }
    
    @objc private func finishButtonTapped() {
        delegate?.didTapFinishButton()
    }
    
    @objc private func addPhotoButtonTapped() {
        delegate?.didTapAddPhotoButton()
    }
    
    // MARK: - Public Methods
    func updateSteps(_ steps: Int) {
        walkTrackingView.updateSteps(steps)
    }
    
    func updateDistance(_ distance: Double) {
        walkTrackingView.updateDistance(distance)
    }
    
    func updateCalories(_ calories: Double) {
        walkTrackingView.updateCalories(calories)
    }
    
    func updateTime(_ timeInterval: TimeInterval) {
        walkTrackingView.updateTime(timeInterval)
    }
    
    func addPhoto(_ image: UIImage) {
        walkTrackingView.addPhoto(image)
    }
}


extension WalkTrackingSheetViewController: UISheetPresentationControllerDelegate {
    // 시트 높이 변경 시 호출되는 메서드
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        // 현재 선택된 detent가 무엇인지 로깅 (디버깅 용도)
        print("시트 높이 변경: \(String(describing: sheetPresentationController.selectedDetentIdentifier))")
        
        // 최소 높이(손잡이만 보이는 상태)일 때 시각적 피드백 처리 가능
        if #available(iOS 16.0, *) {
            UIView.animate(withDuration: 0.1) { [weak self] in
                if sheetPresentationController.selectedDetentIdentifier == .init(rawValue: "normal") {
                    self?.walkTrackingView.fadeInContentAfterMaximize()
                } else {
                    self?.walkTrackingView.fadeOutContentForMinimize()
                }
            }
        }
    }
}


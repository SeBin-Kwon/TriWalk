//
//  ToastView.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/3/25.
//

import UIKit
import SnapKit

final class ToastView: UIView {
    
    // MARK: - Enums
    
    /// 토스트 위치
    enum Position {
        case top
        case center
        case bottom
    }
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = Font.bodyMedium
        label.numberOfLines = 0 // 여러 줄 허용
        label.textAlignment = .left // 왼쪽 정렬로 변경
        label.lineBreakMode = .byWordWrapping // 단어 단위로 줄바꿈
        return label
    }()
    
    // MARK: - Properties
    private var hideTimer: Timer?
    private var completion: (() -> Void)?
    private var position: Position
    
    // MARK: - Initialization
    init(message: String, icon: SFSymbol? = nil, position: Position = .top) {
        self.position = position
        super.init(frame: .zero)
        messageLabel.text = message
        
        if let icon = icon {
            iconImageView.image = UIImage(systemName: icon.rawValue)
        }
        
        backgroundColor = .clear
        setupLayout()
        
        // 처음에는 투명 상태로 시작
        alpha = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        hideTimer?.invalidate()
    }
    
    // MARK: - Private Methods
    private func setupLayout() {
        addSubview(containerView)
        containerView.addSubviews(iconImageView, messageLabel)
        
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20) // 가로 여백 줄임
            make.centerX.equalToSuperview()
            make.height.greaterThanOrEqualTo(50)
            make.width.lessThanOrEqualToSuperview().inset(20).priority(.high) // 화면보다 작게 유지
            
            // 위치에 따라 제약 조건 설정
            switch position {
            case .top:
                make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(20)
            case .center:
                make.center.equalToSuperview()
            case .bottom:
                make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-20)
            }
        }
        
        if iconImageView.image != nil {
            iconImageView.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(16)
                make.top.equalToSuperview().inset(16)
                make.width.height.equalTo(24)
            }
            
            messageLabel.snp.makeConstraints { make in
                make.leading.equalTo(iconImageView.snp.trailing).offset(12)
                make.trailing.equalToSuperview().inset(16)
                make.top.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().inset(16)
            }
        } else {
            iconImageView.isHidden = true
            
            messageLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(16)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 토스트 메시지 표시
    /// - Parameters:
    ///   - duration: 표시 시간 (초)
    ///   - completion: 사라진 후 실행될 클로저
    func show(duration: TimeInterval = 2.0, completion: (() -> Void)? = nil) {
        self.completion = completion
        
        // 위치에 따른 시작 변환 설정
        let startTransform: CGAffineTransform
        switch position {
        case .top:
            startTransform = CGAffineTransform(translationX: 0, y: -100)
        case .center:
            startTransform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        case .bottom:
            startTransform = CGAffineTransform(translationX: 0, y: 100)
        }
        
        containerView.transform = startTransform
        alpha = 1.0
        
        // 애니메이션
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.5,
                       options: [],
                       animations: {
            self.containerView.transform = .identity
        })
        
        // 지정된 시간 후 자동으로 숨김
        hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }
    
    /// 토스트 메시지 숨김
    func hide() {
        // 위치에 따른 종료 변환 설정
        let endTransform: CGAffineTransform
        switch position {
        case .top:
            endTransform = CGAffineTransform(translationX: 0, y: -100)
        case .center:
            endTransform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        case .bottom:
            endTransform = CGAffineTransform(translationX: 0, y: 100)
        }
        
        // 애니메이션으로 사라짐
        UIView.animate(withDuration: 0.3, animations: {
            self.containerView.transform = endTransform
            self.alpha = 0.0
        }, completion: { _ in
            self.removeFromSuperview()
            self.completion?()
        })
    }
    
    // MARK: - 간편 표시 메서드 (정적)
    
    /// 뷰 컨트롤러에 토스트 메시지 표시
    /// - Parameters:
    ///   - viewController: 표시할 대상 뷰 컨트롤러
    ///   - message: 메시지 내용
    ///   - icon: 아이콘 (옵션)
    ///   - position: 토스트 위치 (상단, 중앙, 하단)
    ///   - duration: 표시 시간 (초)
    ///   - completion: 사라진 후 실행될 클로저
    static func show(
        in viewController: UIViewController,
        message: String,
        icon: SFSymbol? = nil,
        position: Position = .top,
        duration: TimeInterval = 2.0,
        completion: (() -> Void)? = nil
    ) {
        let toastView = ToastView(message: message, icon: icon, position: position)
        
        // 뷰 컨트롤러에 추가
        viewController.view.addSubview(toastView)
        
        // 레이아웃 설정
        toastView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 화면에 표시
        toastView.show(duration: duration, completion: completion)
    }
    
    /// 경고 토스트 표시
    static func showAlert(
        in viewController: UIViewController,
        message: String,
        position: Position = .top,
        duration: TimeInterval = 2.0,
        completion: (() -> Void)? = nil
    ) {
        show(
            in: viewController,
            message: message,
            icon: .warning,
            position: position,
            duration: duration,
            completion: completion
        )
    }
    
    /// 성공 토스트 표시
    static func showSuccess(
        in viewController: UIViewController,
        message: String,
        position: Position = .top,
        duration: TimeInterval = 2.0,
        completion: (() -> Void)? = nil
    ) {
        show(
            in: viewController,
            message: message,
            icon: .checkmark,
            position: position,
            duration: duration,
            completion: completion
        )
    }
    
    /// 정보 토스트 표시
    static func showInfo(
        in viewController: UIViewController,
        message: String,
        position: Position = .top,
        duration: TimeInterval = 2.0,
        completion: (() -> Void)? = nil
    ) {
        show(
            in: viewController,
            message: message,
            icon: .info,
            position: position,
            duration: duration,
            completion: completion
        )
    }
    
    /// 위치 관련 토스트 표시
    static func showLocation(
        in viewController: UIViewController,
        message: String,
        position: Position = .top,
        duration: TimeInterval = 2.0,
        completion: (() -> Void)? = nil
    ) {
        show(
            in: viewController,
            message: message,
            icon: .location,
            position: position,
            duration: duration,
            completion: completion
        )
    }
}

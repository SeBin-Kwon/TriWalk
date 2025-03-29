//
//  ConfigButton.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/28/25.
//

import UIKit

class ConfigButton: UIButton {
    
    // MARK: - 초기화
    init(title: String? = nil) {
        super.init(frame: .zero)
        setupWithConfiguration(title: title)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWithConfiguration(title: nil)
    }
    
    // MARK: - Configuration 설정
    private func setupWithConfiguration(title: String?) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = .triWalkPrimary
        config.baseForegroundColor = .contentPrimary
        config.cornerStyle = .capsule
        
        // 기본 패딩 설정
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        
        // 기본 폰트 설정
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Font.font(size: 14, weight: .medium)
            return outgoing
        }
        
        // 버튼 상태 설정
        configurationUpdateHandler = { button in
            var updatedConfig = button.configuration
            
            switch button.state {
            case .highlighted:
                updatedConfig?.baseBackgroundColor = button.configuration?.baseBackgroundColor?.withAlphaComponent(0.7)
            case .disabled:
                updatedConfig?.baseBackgroundColor = button.configuration?.baseBackgroundColor?.withAlphaComponent(0.4)
            default:
                updatedConfig?.baseBackgroundColor = button.configuration?.baseBackgroundColor?.withAlphaComponent(1.0)
            }
            
            button.configuration = updatedConfig
        }
        
        self.configuration = config
    }
    
    // MARK: - 기본 스타일 설정 메소드
    
    /// 배경색 설정
    @discardableResult
    func setBackgroundColor(_ color: UIColor) -> Self {
        var updatedConfig = self.configuration
        updatedConfig?.baseBackgroundColor = color
        self.configuration = updatedConfig
        return self
    }
    
    /// 텍스트 색상 설정
    @discardableResult
    func setTextColor(_ color: UIColor) -> Self {
        var updatedConfig = self.configuration
        updatedConfig?.baseForegroundColor = color
        self.configuration = updatedConfig
        return self
    }
    
    /// 폰트 설정
    @discardableResult
    func setFont(size: CGFloat, weight: Font.FontWeight) -> Self {
        var updatedConfig = self.configuration
        updatedConfig?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Font.font(size: size, weight: weight)
            return outgoing
        }
        self.configuration = updatedConfig
        return self
    }
    
    /// 모서리 둥글기 설정
    @discardableResult
    func setCornerRadius(_ radius: CGFloat) -> Self {
        var updatedConfig = self.configuration
        updatedConfig?.background.cornerRadius = radius
        self.configuration = updatedConfig
        return self
    }
    
    /// 모서리 완전히 둥글게 설정 (캡슐 모양)
    @discardableResult
    func makeRounded() -> Self {
        var updatedConfig = self.configuration
        updatedConfig?.cornerStyle = .capsule
        self.configuration = updatedConfig
        return self
    }
    
    /// 테두리 설정
    @discardableResult
    func setBorder(width: CGFloat, color: UIColor) -> Self {
        var updatedConfig = self.configuration
        updatedConfig?.background.strokeWidth = width
        updatedConfig?.background.strokeColor = color
        self.configuration = updatedConfig
        return self
    }
    
    /// 아이콘 추가
    @discardableResult
    func setIcon(symbol: SFSymbol, position: NSDirectionalRectEdge = .leading, spacing: CGFloat = 8) -> Self {
        let image = UIImage(systemName: symbol.rawValue)
        var updatedConfig = self.configuration
        updatedConfig?.image = image
        
        if position == .leading {
            updatedConfig?.imagePlacement = .leading
        } else {
            updatedConfig?.imagePlacement = .trailing
        }
        
        updatedConfig?.imagePadding = spacing
        self.configuration = updatedConfig
        return self
    }
    
    /// 패딩 설정
    @discardableResult
    func setPadding(horizontal: CGFloat, vertical: CGFloat) -> Self {
        var updatedConfig = self.configuration
        updatedConfig?.contentInsets = NSDirectionalEdgeInsets(
            top: vertical,
            leading: horizontal,
            bottom: vertical,
            trailing: horizontal
        )
        self.configuration = updatedConfig
        return self
    }
}

// MARK: - 기본 스타일 메소드
extension ConfigButton {
    /// 기본 버튼 스타일
    static func primary(title: String) -> ConfigButton {
        return ConfigButton(title: title)
    }
    
    /// 아웃라인 버튼 스타일
    static func outline(title: String) -> ConfigButton {
        let button = ConfigButton(title: title)
        var config = UIButton.Configuration.bordered()
        config.title = title
        config.baseForegroundColor = Color.contentPrimary
        config.background.strokeColor = Color.contentPrimary
        config.background.strokeWidth = 1
        config.background.backgroundColor = .clear
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Font.font(size: 14, weight: .medium)
            return outgoing
        }
        
        button.configuration = config
        return button
    }
    
    /// 텍스트 버튼 스타일
    static func text(title: String) -> ConfigButton {
        let button = ConfigButton(title: title)
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = Color.textBlue
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Font.font(size: 14, weight: .medium)
            return outgoing
        }
        
        button.configuration = config
        return button
    }
}

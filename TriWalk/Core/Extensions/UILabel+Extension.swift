//
//  UILabel+Extension.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/28/25.
//
import UIKit

extension UILabel {
    // 타이틀 스타일 적용
    func applyHeading1Style(color: UIColor = Color.contentPrimary) {
        self.font = Font.heading1
        self.textColor = color
        self.numberOfLines = 0
    }
    
    func applyHeading2Style(color: UIColor = Color.contentPrimary) {
        self.font = Font.heading2
        self.textColor = color
        self.numberOfLines = 0
    }
    
    func applyHeading3Style(color: UIColor = Color.contentPrimary) {
        self.font = Font.heading3
        self.textColor = color
        self.numberOfLines = 0
    }
    
    // 본문 스타일 적용
    func applyBodyLargeStyle(color: UIColor = Color.contentPrimary) {
        self.font = Font.bodyLarge
        self.textColor = color
        self.numberOfLines = 0
    }
    
    func applyBodyMediumStyle(color: UIColor = Color.contentPrimary) {
        self.font = Font.bodyMedium
        self.textColor = color
        self.numberOfLines = 0
    }
    
    func applyBodySmallStyle(color: UIColor = Color.contentPrimary) {
        self.font = Font.bodySmall
        self.textColor = color
        self.numberOfLines = 0
    }
    
    func applyButtonStyle(color: UIColor = Color.contentPrimary) {
        self.font = Font.button
        self.textColor = color
        self.numberOfLines = 0
    }
    
    func applyCaptionStyle(color: UIColor = Color.textSecondary) {
        self.font = Font.caption
        self.textColor = color
        self.numberOfLines = 0
    }
    
    func applyOverlineStyle(color: UIColor = Color.textSecondary) {
        self.font = Font.overline
        self.textColor = color
        self.numberOfLines = 0
    }
}

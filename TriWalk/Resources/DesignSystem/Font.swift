//
//  Font.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/27/25.
//

import UIKit

enum Font {
    enum FontWeight {
        case regular, medium, semibold, bold
        
        var weight: UIFont.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            }
        }
    }
    
    static func font(size: CGFloat, weight: FontWeight = .regular) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: weight.weight)
    }
    
    static let heading1 = font(size: 27, weight: .bold)
    static let heading2 = font(size: 24, weight: .bold)
    static let heading3 = font(size: 20, weight: .semibold)
    
    static let bodyLarge = font(size: 18, weight: .regular)
    static let bodyMedium = font(size: 16, weight: .regular)
    static let bodySmall = font(size: 14, weight: .regular)
    
    static let button = font(size: 16, weight: .medium)
    static let caption = font(size: 12, weight: .regular)
    static let overline = font(size: 10, weight: .medium)
}

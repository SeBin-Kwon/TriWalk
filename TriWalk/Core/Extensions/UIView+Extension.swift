//
//  UIView+Extension.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/27/25.
//
import UIKit

extension UIView {
    func addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }
    
    func roundCorners(radius: CGFloat = 8) {
        layer.cornerRadius = radius
        clipsToBounds = true
    }
    
    func addShadow(
        color: UIColor = .black,
        opacity: Float = 0.1,
        offset: CGSize = CGSize(width: 0, height: 2),
        radius: CGFloat = 4
    ) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
    }
}

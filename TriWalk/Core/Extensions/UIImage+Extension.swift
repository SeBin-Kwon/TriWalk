//
//  UIImage+Extension.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/28/25.
//

import UIKit

extension UIImage {
    convenience init?(symbol: SFSymbol) {
        self.init(systemName: symbol.rawValue)
    }
    func withRoundedCorners(radius: CGFloat, borderWidth: CGFloat = 0, borderColor: UIColor? = nil) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            let rect = CGRect(origin: .zero, size: size)
            
            // 클리핑 경로 설정 (둥근 모서리)
            UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
            draw(in: rect)
            
            // 테두리 추가
            if borderWidth > 0, let borderColor = borderColor {
                let context = UIGraphicsGetCurrentContext()
                context?.setLineWidth(borderWidth)
                context?.setStrokeColor(borderColor.cgColor)
                let borderRect = rect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
                let borderPath = UIBezierPath(roundedRect: borderRect, cornerRadius: radius - borderWidth / 2)
                borderPath.stroke()
            }
            
            let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return roundedImage
    }
}

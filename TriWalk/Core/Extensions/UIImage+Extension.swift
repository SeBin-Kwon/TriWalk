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
}

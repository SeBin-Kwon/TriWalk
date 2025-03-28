//
//  UIViewController+Extension.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/28/25.
//

import UIKit

extension UIViewController {
    func navigate(_ type: NavigationType) {
        switch type {
        case .push(let vc): self.navigationController?.pushViewController(vc, animated: true)
        case .pop: self.navigationController?.popViewController(animated: true)
        case .present(let vc): self.present(vc, animated: true)
        case .dismiss: self.dismiss(animated: true)
        }
    }
}

enum NavigationType {
    case push(UIViewController)
    case pop
    case present(UIViewController)
    case dismiss
}

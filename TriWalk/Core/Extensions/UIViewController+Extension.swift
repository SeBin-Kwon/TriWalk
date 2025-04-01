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
    
    func changeRootViewController(rootView: UIViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        UIView.transition(with: window,
                                 duration: 0.5,
                                 options: .transitionCrossDissolve,
                          animations: {
            if let pageView = rootView as? UIPageViewController {
                window.rootViewController = pageView
            } else {
                window.rootViewController = UINavigationController(rootViewController: rootView)
            }
        })
        window.makeKeyAndVisible()
    }
}

enum NavigationType {
    case push(UIViewController)
    case pop
    case present(UIViewController)
    case dismiss
}

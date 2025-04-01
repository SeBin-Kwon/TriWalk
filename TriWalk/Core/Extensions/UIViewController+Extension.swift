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
        
        // 현재 화면의 스냅샷 생성
        guard let snapshot = window.snapshotView(afterScreenUpdates: false) else {
            // 스냅샷을 만들 수 없는 경우 기본 전환 사용
            if let pageView = rootView as? UIPageViewController {
                window.rootViewController = pageView
            } else {
                window.rootViewController = UINavigationController(rootViewController: rootView)
            }
            window.makeKeyAndVisible()
            return
        }
        
        // 루트 뷰 컨트롤러 변경 (애니메이션 없이)
        if let pageView = rootView as? UIPageViewController {
            window.rootViewController = pageView
        } else {
            window.rootViewController = UINavigationController(rootViewController: rootView)
        }
        
        // 스냅샷을 화면 위에 추가
        window.addSubview(snapshot)
        
        // 스냅샷을 페이드 아웃하여 새 화면 표시
        UIView.animate(withDuration: 0.5, animations: {
            snapshot.alpha = 0
        }, completion: { _ in
            // 애니메이션 완료 후 스냅샷 제거
            snapshot.removeFromSuperview()
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

//
//  AlertService.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/10/25.
//

import UIKit

protocol AlertServiceProtocol {
    func showAlert(on viewController: UIViewController,
                  title: String,
                  message: String,
                  actions: [UIAlertAction])
    
    func showSettingsAlert(on viewController: UIViewController,
                          title: String,
                          message: String)
    
    func showErrorAlert(on viewController: UIViewController,
                       title: String,
                       message: String)
    
    func showConfirmationAlert(on viewController: UIViewController,
                             title: String,
                             message: String,
                             confirmAction: @escaping () -> Void)
    
    func showDeleteAlert(on viewController: UIViewController,
                        title: String,
                        message: String,
                        confirmAction: @escaping () -> Void)
}

final class AlertService: AlertServiceProtocol {
    // 기본 알림창 표시
    func showAlert(on viewController: UIViewController,
                  title: String,
                  message: String,
                  actions: [UIAlertAction]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // 액션이 없으면 기본 "확인" 액션 추가
        if actions.isEmpty {
            alert.addAction(UIAlertAction(title: "확인", style: .default))
        } else {
            actions.forEach { alert.addAction($0) }
        }
        
        viewController.present(alert, animated: true)
    }
    
    // 설정으로 이동하는 알림창
    func showSettingsAlert(on viewController: UIViewController,
                          title: String,
                          message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        viewController.present(alert, animated: true)
    }
    
    // 오류 알림창
    func showErrorAlert(on viewController: UIViewController,
                       title: String,
                       message: String) {
        let alert = UIAlertController(
            title: title.isEmpty ? "오류" : title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        
        viewController.present(alert, animated: true)
    }
    
    // 확인 알림창
    func showConfirmationAlert(on viewController: UIViewController,
                             title: String,
                             message: String,
                             confirmAction: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            confirmAction()
        })
        
        viewController.present(alert, animated: true)
    }
    
    func showDeleteAlert(on viewController: UIViewController,
                             title: String,
                             message: String,
                             confirmAction: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive) { _ in
            confirmAction()
        })
        
        viewController.present(alert, animated: true)
    }
}

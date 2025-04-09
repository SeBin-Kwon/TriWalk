//
//  NotificationCenterManager.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/9/25.
//

import UIKit
import Combine

protocol NotificationCenterHandler {
    var name: Notification.Name { get }
}

extension NotificationCenterHandler {
    func publisher() -> AnyPublisher<Any?, Never> {
        NotificationCenter.default
            .publisher(for: name)
            .map { $0.object }
            .eraseToAnyPublisher()
    }

    func post(object: Any? = nil) {
        NotificationCenter.default.post(name: name, object: object, userInfo: nil)
    }
}

enum NotificationCenterManager: NotificationCenterHandler {
    case didEnterBackground
    case willEnterForeground

    var name: Notification.Name {
        switch self {
        case .didEnterBackground:
            return UIApplication.didEnterBackgroundNotification
        case .willEnterForeground:
            return UIApplication.willEnterForegroundNotification
        }
    }
}


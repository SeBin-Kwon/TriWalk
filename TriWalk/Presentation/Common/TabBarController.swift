//
//  TabBarController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/28/25.
//

import UIKit

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
    }
    
    private func setupTabBar() {
        // 탭바 외관 설정
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .background
        
        // 선택/비선택 상태의 아이템 색상 설정
        let normalAttributes: [NSAttributedString.Key: UIColor] = [
            .foregroundColor: .textSecondary
        ]
        let selectedAttributes: [NSAttributedString.Key: UIColor] = [
            .foregroundColor: .contentPrimary
        ]
        
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        
        // 선택 아이템 색상 설정
        tabBar.tintColor = .contentPrimary
    }
    
    private func setupViewControllers() {
        // 홈 탭
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "홈",
            image: UIImage(symbol: .home),
            tag: 0
        )
        
        // 캘린더 탭
        let calendarVC = /*CalendarViewController()*/ UIViewController()
        let calendarNav = UINavigationController(rootViewController: calendarVC)
        calendarNav.tabBarItem = UITabBarItem(
            title: "기록",
            image: UIImage(symbol: .calendar),
            tag: 1
        )
        
        // 사진 탭
        let photoVC = /*PhotoViewController()*/UIViewController()
        let photoNav = UINavigationController(rootViewController: photoVC)
        photoNav.tabBarItem = UITabBarItem(
            title: "사진",
            image: UIImage(symbol: .photo),
            tag: 2
        )
        
        self.viewControllers = [homeNav, calendarNav, photoNav]
        self.selectedIndex = 0
    }
}

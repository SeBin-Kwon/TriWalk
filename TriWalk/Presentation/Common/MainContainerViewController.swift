//
//  MainContainerViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/28/25.
//

import UIKit

class MainContainerViewController: UIPageViewController {
    
    // 페이지 관리
    private var homeVC: HomeViewController!
    private var detailVC: DetailViewController!
    private var homeNavController: UINavigationController!
    //    private var detailNavController: UINavigationController!
    private var isSwipeEnabled = true
    
    // 초기화
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .vertical)
    }
    
    required init?(coder: NSCoder) {
        super.init(transitionStyle: .scroll, navigationOrientation: .vertical, options: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewControllers()
        setupPageViewController()
    }
    
    private func setupViewControllers() {
        // 홈 화면 설정
        homeVC = HomeViewController()
        homeVC.delegate = self
        homeNavController = UINavigationController(rootViewController: homeVC)
        
        homeNavController.delegate = self
        // 디테일 화면 설정
        detailVC = DetailViewController()
        
        // 홈 화면으로 시작
        setViewControllers([homeNavController], direction: .forward, animated: false)
    }
    
    private func setupPageViewController() {
        dataSource = self
        delegate = self
        
    }
    
    // 워크 플로우 시작 (Home -> WalkSetup)
    func startWalkFlow() {
        let walkSetupVC = WalkSetupViewController()
        walkSetupVC.delegate = self
        
        isSwipeEnabled = false
       enableSwiping(false)
        
        homeVC.navigate(.push(walkSetupVC))
    }
    
    // Home 화면으로 돌아가기
    func returnToHome() {
        // 네비게이션 스택의 루트 뷰 컨트롤러로 이동 (모든 중간 화면 제거)
        homeVC.navigationController?.popToRootViewController(animated: true)
        
        // 페이지 뷰 컨트롤러를 홈 네비게이션 컨트롤러로 설정
        setViewControllers([homeNavController], direction: .forward, animated: true)
        
        // 스와이프 기능 활성화 (Home에서만 스와이프 가능하도록)
        isSwipeEnabled = true
        enableSwiping()
    }
    
    
    
    // 스와이프 기능 활성화/비활성화
    func enableSwiping(_ enabled: Bool = true) {
        if let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.isScrollEnabled = enabled
        }
    }
}

// MARK: - UIPageViewControllerDataSource
extension MainContainerViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        // 디테일 화면에서 홈 화면으로
        if viewController == detailVC {
            return homeNavController
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        // 홈 화면에서만 디테일 화면으로 이동 가능
        if viewController == homeNavController && isSwipeEnabled {
                return detailVC
            }
            return nil
        
    }
}

// MARK: - UIPageViewControllerDelegate
extension MainContainerViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        // 페이지 전환이 완료된 후 처리할 내용
    }
}

// MARK: - HomeViewController Delegate
protocol HomeViewControllerDelegate: AnyObject {
    func didTapStartButton()
}

// MARK: - WalkSetupViewController Delegate
protocol WalkSetupViewControllerDelegate: AnyObject {
    func didTapStartWalkingButton()
    func didTapBackButton()
}

// MARK: - WalkTrackingViewController Delegate
protocol WalkTrackingViewControllerDelegate: AnyObject {
    func didTapFinishButton()
}

// MARK: - WalkCompletedViewController Delegate
protocol WalkCompletedViewControllerDelegate: AnyObject {
    func didTapReturnHomeButton()
}

// MARK: - MainContainer와 각 화면 간 연결
extension MainContainerViewController: HomeViewControllerDelegate, WalkSetupViewControllerDelegate, WalkTrackingViewControllerDelegate, WalkCompletedViewControllerDelegate {
    // HomeViewController에서 시작 버튼 탭
    func didTapStartButton() {
        startWalkFlow()
    }
    
    // WalkSetupViewController에서 시작 버튼 탭
    func didTapStartWalkingButton() {
        let walkTrackingVC = WalkTrackingViewController()
        walkTrackingVC.delegate = self
        walkTrackingVC.modalPresentationStyle = .fullScreen
        
        // 이 화면에서는 뒤로 가기 불가능하게 모달로 표시
        homeVC.navigationController?.present(walkTrackingVC, animated: true)
        // 기존 화면 닫고 새 화면 열기 (뒤로가기 방지)
        //        if let presented = presentedViewController {
        //            presented.dismiss(animated: false) {
        //                self.present(walkTrackingVC, animated: true)
        //            }
        //        } else {
        //            present(walkTrackingVC, animated: true)
        //        }
    }
    
    // WalkSetupViewController에서 뒤로가기 버튼 탭
    func didTapBackButton() {
        // 모달 닫기만 하면 됨
        isSwipeEnabled = true
        enableSwiping(true)
        homeVC.navigationController?.popViewController(animated: true)
    }
    
    // WalkTrackingViewController에서 종료 버튼 탭
    func didTapFinishButton() {
        let walkCompletedVC = WalkCompletedViewController()
        walkCompletedVC.delegate = self
        walkCompletedVC.modalPresentationStyle = .fullScreen
        
        // 기존 화면 닫고 새 화면 열기 (뒤로가기 방지)
        
        if let presented = homeVC.navigationController?.presentedViewController {
            presented.dismiss(animated: false) {
                self.homeVC.navigationController?.present(walkCompletedVC, animated: true)
            }
        } else {
            homeVC.navigationController?.present(walkCompletedVC, animated: true)
        }
    }
    
    // WalkCompletedViewController에서 홈으로 버튼 탭
    func didTapReturnHomeButton() {
        // 모든 화면 닫고 홈으로
        homeVC.navigationController?.dismiss(animated: true) {
            self.returnToHome()
        }
    }
}


extension MainContainerViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // 홈 화면이 다시 표시되었는지 확인
        if viewController == homeVC {
            // 홈 화면으로 돌아왔으므로 스와이프 활성화
            isSwipeEnabled = true
            enableSwiping(true)
        } else {
            // 다른 화면이 표시되었으므로 스와이프 비활성화
            isSwipeEnabled = false
            enableSwiping(false)
        }
    }
}

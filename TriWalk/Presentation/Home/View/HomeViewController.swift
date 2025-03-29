//
//  HomeViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/28/25.
//

import UIKit
import Combine
import SnapKit

class HomeViewController: BaseViewController {
    weak var delegate: HomeViewControllerDelegate?
    
    let titleLabel = {
        let label = UILabel()
        label.text = "오늘은 산책 여행 하기\n딱 좋은 날씨!"
        label.applyHeading1Style()
        return label
    }()
    
    let cardView = HomeCardView()
    
    let startButton = ConfigButton(title: "산책 여행 떠나기")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
    }
    
    override func bindViewModel() {
        startButton.controlPublisher(for: .touchUpInside)
            .withUnretained(self)
            .sink { owner, _ in
                owner.delegate?.didTapStartButton()
//                let vc = WalkSetupViewController()
//                owner.navigate(.push(vc))
            }
            .store(in: &cancellables)
    }
    
    private func setupNavigationBar() {
        let chartButton = UIBarButtonItem(image: UIImage(symbol: .chartBar), style: .plain, target: self, action: #selector(chartButtonTap))
        navigationItem.rightBarButtonItem = chartButton
    }
    
    @objc private func chartButtonTap() {
        print("chart")
    }
    
    @objc private func calendarButtonTap() {
        print("calendar")
    }
    
    override func configureHierarchy() {
        view.addSubviews(titleLabel, startButton, cardView)
    }
    
    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalTo(view.safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
        
        cardView.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
            make.width.equalTo(310)
            make.height.equalTo(480)
        }
        
        startButton.snp.makeConstraints { make in
            make.bottom.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(Spacing.screenMargin)
        }
    }
    
    override func configureView() {
        startButton.applyHomeButtonStyle()
    }
}



//import UIKit
//
//// 메인 컨테이너 컨트롤러
//class MainContainerViewController: UIPageViewController, UIPageViewControllerDelegate {
//    
//    private var pages = [UIViewController]()
//    private var isSwipeEnabled = true
//    
//    init() {
//        super.init(transitionStyle: .scroll, navigationOrientation: .vertical)
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(transitionStyle: .scroll, navigationOrientation: .vertical, options: nil)
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        self.dataSource = self
//        self.delegate = self
//        self.view.backgroundColor = .clear
//        
//        // 페이지 설정
//        let homeVC = HomeViewController()
//        homeVC.delegate = self
//        
//        let detailVC = DetailViewController()
//        
//        pages = [homeVC, detailVC]
//        
//        // 첫 페이지 설정
//        setViewControllers([pages[0]], direction: .forward, animated: true)
//    }
//    
//    // 스와이프 활성화/비활성화 함수
//    func setSwipeEnabled(_ enabled: Bool) {
//        isSwipeEnabled = enabled
//        
//        // 스크롤뷰 찾아서 스와이프 제스처 활성화/비활성화
//        if let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
//            scrollView.isScrollEnabled = enabled
//        }
//    }
//    
//    // 프로그래매틱하게 워크셋업 화면으로 이동
//    func navigateToWalkSetup() {
//        let walkSetupVC = WalkSetupViewController()
//        
//        // 이전 화면으로 돌아갈 때 사용할 딜리게이트 설정
//        walkSetupVC.delegate = self
//        
//        // 네비게이션 컨트롤러가 있다면 푸시, 없다면 모달로 표시
//        if let navigationController = viewControllers?.first?.navigationController {
//            navigationController.pushViewController(walkSetupVC, animated: true)
//        } else {
//            walkSetupVC.modalPresentationStyle = .fullScreen
//            present(walkSetupVC, animated: true)
//        }
//    }
//}
//
//// UIPageViewControllerDataSource 구현
//extension MainContainerViewController: UIPageViewControllerDataSource {
//    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
//        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
//            return nil
//        }
//        
//        let previousIndex = viewControllerIndex - 1
//        guard previousIndex >= 0 else {
//            return nil
//        }
//        
//        return pages[previousIndex]
//    }
//    
//    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
//        // 현재 페이지가 HomeViewController가 아니면 nil 반환하여 스와이프 방지
//        if !(viewController is HomeViewController) || !isSwipeEnabled {
//            return nil
//        }
//        
//        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
//            return nil
//        }
//        
//        let nextIndex = viewControllerIndex + 1
//        guard nextIndex < pages.count else {
//            return nil
//        }
//        
//        return pages[nextIndex]
//    }
//}
//
//// 홈 뷰 컨트롤러에서 이벤트를 처리하기 위한 프로토콜
//protocol HomeViewControllerDelegate: AnyObject {
//    func didTapStartButton()
//}
//
//
//
//// MainContainerViewController와 HomeViewController 연결
//extension MainContainerViewController: HomeViewControllerDelegate {
//    func didTapStartButton() {
//        // 시작 버튼 탭 시 WalkSetupViewController로 이동
//        navigateToWalkSetup()
//    }
//}
//
//// 워크셋업 컨트롤러 델리게이트
//protocol WalkSetupViewControllerDelegate: AnyObject {
//    func walkSetupDidFinish()
//}
//
//// WalkSetupViewController와 MainContainerViewController 연결
//extension MainContainerViewController: WalkSetupViewControllerDelegate {
//    func walkSetupDidFinish() {
//        // 워크셋업 화면이 종료되었을 때 필요한 작업
//        // 예: 스와이프 다시 활성화
//        setSwipeEnabled(true)
//    }
//}


// 상세 화면
class DetailViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // UI 요소 설정
        let titleLabel = UILabel()
        titleLabel.text = "상세 화면"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        // 스와이프 안내 레이블
        let instructionLabel = UILabel()
        instructionLabel.text = "아래로 스와이프하여 홈 페이지로 돌아가기"
        instructionLabel.font = .systemFont(ofSize: 16)
        instructionLabel.textAlignment = .center
        instructionLabel.textColor = .systemGray
        
        view.addSubview(instructionLabel)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])
    }
}


class WalkTrackingViewController: UIViewController {
    weak var delegate: WalkTrackingViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // UI 요소 설정
        let titleLabel = UILabel()
        titleLabel.text = "상세 화면"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        // 스와이프 안내 레이블
        let instructionLabel = UILabel()
        instructionLabel.text = "아래로 스와이프하여 홈 페이지로 돌아가기"
        instructionLabel.font = .systemFont(ofSize: 16)
        instructionLabel.textAlignment = .center
        instructionLabel.textColor = .systemGray
        
        view.addSubview(instructionLabel)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])
    }
}


class WalkCompletedViewController: UIViewController {
    weak var delegate: WalkCompletedViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // UI 요소 설정
        let titleLabel = UILabel()
        titleLabel.text = "상세 화면"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        // 스와이프 안내 레이블
        let instructionLabel = UILabel()
        instructionLabel.text = "아래로 스와이프하여 홈 페이지로 돌아가기"
        instructionLabel.font = .systemFont(ofSize: 16)
        instructionLabel.textAlignment = .center
        instructionLabel.textColor = .systemGray
        
        view.addSubview(instructionLabel)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])
    }
}

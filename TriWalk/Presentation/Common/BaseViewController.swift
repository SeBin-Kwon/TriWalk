//
//  BaseViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/27/25.
//

import UIKit
import Combine

class BaseViewController: UIViewController {
    var cancellables = Set<AnyCancellable>()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Color.background
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        configureHierarchy()
        configureLayout()
        configureView()
        bindViewModel()
    }
    func configureHierarchy() {}
    func configureLayout() {}
    func configureView() {}
    func bindViewModel() {}
    
    deinit {
        cancellables.removeAll()
        print("\(type(of: self)) deinited")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

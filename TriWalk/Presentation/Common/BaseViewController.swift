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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        bindViewModel()
    }
    
    func configureView() {
        view.backgroundColor = Color.background
    }
    
    func bindViewModel() {
    }
    
    deinit {
        cancellables.removeAll()
        print("\(type(of: self)) deinited")
    }
}

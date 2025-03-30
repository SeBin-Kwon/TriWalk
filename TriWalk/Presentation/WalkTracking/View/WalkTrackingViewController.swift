//
//  WalkTrackingViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/31/25.
//

import UIKit

final class WalkTrackingViewController: BaseViewController {
    weak var delegate: WalkTrackingViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .textBlue
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

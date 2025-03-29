//
//  HomeCardView.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/29/25.
//

import UIKit
import SnapKit

final class HomeCardView: BaseView {

    let iconView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "sun")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override func configureHierarchy() {
        backgroundColor = .white
        addSubviews(iconView)
    }
    override func configureLayout() {
        iconView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(30)
        }
    }
}

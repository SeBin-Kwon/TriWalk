//
//  WalkDetailPhotoCell.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/11/25.
//

import UIKit
import SnapKit

class WalkDetailPhotoCell: BaseCollectionViewCell {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    override func configureLayout() {
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func configure(with image: UIImage) {
        imageView.image = image
    }
}

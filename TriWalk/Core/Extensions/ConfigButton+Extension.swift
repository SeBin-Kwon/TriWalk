//
//  ConfigButton+Extension.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/28/25.
//

import Foundation

extension ConfigButton {
    func applyHomeButtonStyle() {
        setFont(size: 16, weight: .bold)
                setPadding(horizontal: 24, vertical: 16)
        self.snp.makeConstraints { make in
            make.height.equalTo(54)
        }
    }
}

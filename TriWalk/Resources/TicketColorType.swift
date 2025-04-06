//
//  TicketColorType.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/6/25.
//

import UIKit

enum TicketColorType: Int, CaseIterable {
    case ticket1 = 1
    case ticket2 = 2
    case ticket3 = 3
    
    // 랜덤 티켓 색상 생성
    static func random() -> TicketColorType {
        // 1에서 3 사이의 랜덤 숫자 생성
        let randomIndex = Int.random(in: 1...3)
        return TicketColorType(rawValue: randomIndex) ?? .ticket1
    }
    
    // 티켓 이미지 이름 반환
    var imageName: String {
        return "ticket\(self.rawValue)"
    }
    
    // 티켓 이미지 반환
    var image: UIImage? {
        return UIImage(named: imageName)
    }
}

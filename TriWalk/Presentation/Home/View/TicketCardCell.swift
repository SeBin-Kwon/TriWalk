//
//  TicketCardCell.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/4/25.
//

import UIKit
import SnapKit

final class TicketCardCell: BaseCollectionViewCell {
    
    // MARK: - UI Components
    let ticketView = TicketView()
    
    // MARK: - Lifecycle
    override func configureHierarchy() {
        addSubviews(ticketView)
    }
    
    override func configureLayout() {
        ticketView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func configureView() {
        backgroundColor = .clear
    }
    
    // MARK: - Public Methods
    func configure(with data: WalkCompletedData) {
        ticketView.configure(with: data)
    }
}

//
//  SortButton.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/8/25.
//

import UIKit
import Combine
import SnapKit

final class SortButton: ConfigButton {
    
    // MARK: - Properties
    private var subject = PassthroughSubject<Bool, Never>()
    private var isButtonSelected: Bool = false
    
    // 버튼 타입
    enum SortType {
        case latest     // 최신순
        case oldest     // 오래된순
    }
    fileprivate var sortType: SortType = .latest
    
    // 현재 선택된 버튼 타입 (정적 속성)
    static var selectedSortType: SortType = .latest
    
    // MARK: - Publisher
    var publisher: AnyPublisher<Bool, Never> {
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(type: SortType) {
        self.sortType = type
        let title = type == .latest ? "최신순" : "오래된 순"
        super.init(title: title)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        // 초기 선택 상태 설정
        updateSelection(SortButton.selectedSortType == sortType)
        
        // ConfigButton 스타일 설정
        setFont(size: 14, weight: .medium)
        setPadding(horizontal: 15, vertical: 10)
        
        // 액션 추가
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        // 초기 상태 업데이트
        updateAppearance()
    }
    
    // MARK: - Actions
    @objc private func buttonTapped() {
        // 이미 선택된 버튼이면 아무 동작 하지 않음
        if isButtonSelected { return }
        
        // 선택 상태 변경
        SortButton.selectedSortType = sortType
        updateSelection(true)
        subject.send(isButtonSelected)
    }
    
    // MARK: - Update Methods
    func updateSelection(_ selected: Bool) {
        isButtonSelected = selected
        updateAppearance()
    }
    
    private func updateAppearance() {
        if isButtonSelected {
            // 선택된 상태
            setBackgroundColor(Color.darkContent)
            setTextColor(.background)
            setBorder(width: 0, color: .clear)
        } else {
            // 선택되지 않은 상태
            setBackgroundColor(.background)
            setTextColor(Color.darkContent)
            setBorder(width: 1, color: Color.darkContent)
        }
    }
    
    // 다른 버튼이 선택되었을 때 호출
    func deselectButton() {
        updateSelection(false)
    }
}

// MARK: - 정렬 버튼 그룹 (두 개의 버튼을 함께 관리)
class SortButtonGroup {
    private let latestButton = SortButton(type: .latest)
    private let oldestButton = SortButton(type: .oldest)
    private var cancellables = Set<AnyCancellable>()
    
    var selectedPublisher: AnyPublisher<SortOrder, Never> {
        return Publishers.Merge(
            latestButton.publisher.map { _ in SortOrder.descending },
            oldestButton.publisher.map { _ in SortOrder.ascending }
        )
        .eraseToAnyPublisher()
    }
    
    init() {
        // 버튼 간 상호 작용 설정
        latestButton.publisher
            .sink { [weak self] isSelected in
                if isSelected {
                    self?.oldestButton.deselectButton()
                }
            }
            .store(in: &cancellables)
        
        oldestButton.publisher
            .sink { [weak self] isSelected in
                if isSelected {
                    self?.latestButton.deselectButton()
                }
            }
            .store(in: &cancellables)
    }
    
    func addToView(_ view: UIView) {
        view.addSubviews(latestButton, oldestButton)
        
        latestButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(100)
        }
        
        oldestButton.snp.makeConstraints { make in
            make.leading.equalTo(latestButton.snp.trailing).offset(10)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(100)
        }
    }
}

//
//  CalendarView.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/8/25.
//

import UIKit
import SnapKit

protocol CalendarViewDelegate: AnyObject {
    func calendarView(_ calendarView: CalendarView, didSelectDate date: Date?)
    func calendarView(_ calendarView: CalendarView, didChangeMonth date: Date)
}

final class CalendarView: BaseView {
    
    // MARK: - Properties
    weak var delegate: CalendarViewDelegate?
    private var dates: [Date] = []
    private var recordDates: [Date] = []
    private var currentMonth = Date()
    private var selectedDate: Date?
    
    // MARK: - UI Components
    let monthLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = Font.heading3
        label.textColor = Color.darkContent
        return label
    }()
    
    let prevButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = Color.textSecondary
        return button
    }()
    
    let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = Color.textSecondary
        return button
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(CalendarDateCell.self, forCellWithReuseIdentifier: CalendarDateCell.identifier)
        return collectionView
    }()
    
    // MARK: - Setup
    override func configureHierarchy() {
        addSubviews(monthLabel, prevButton, nextButton, collectionView)
    }
    
    override func configureLayout() {
        monthLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        prevButton.snp.makeConstraints { make in
            make.centerY.equalTo(monthLabel)
            make.trailing.equalTo(monthLabel.snp.leading).offset(-20)
            make.size.equalTo(25)
        }
        
        nextButton.snp.makeConstraints { make in
            make.centerY.equalTo(monthLabel)
            make.leading.equalTo(monthLabel.snp.trailing).offset(20)
            make.size.equalTo(25)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(monthLabel.snp.bottom).offset(Spacing.m)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    override func configureView() {
        backgroundColor = .background
        
        setupCollectionView()
        setupActions()
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    private func setupActions() {
        prevButton.addTarget(self, action: #selector(didTapPrevButton), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(didTapNextButton), for: .touchUpInside)
    }
    
    // MARK: - Public Methods
    func configure(with currentDate: Date, recordDates: [Date]) {
        self.currentMonth = currentDate
        self.recordDates = recordDates
        
        // 날짜 데이터 생성
        dates = generateDatesForMonth(date: currentMonth)
        
        // 년월 라벨 업데이트
        updateMonthLabel()
        
        // 컬렉션 뷰 갱신
        collectionView.reloadData()
    }
    
    // 선택 날짜 설정
    func setSelectedDate(_ date: Date?) {
        selectedDate = date
        collectionView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func didTapPrevButton() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? Date()
        dates = generateDatesForMonth(date: currentMonth)
        updateMonthLabel()
        
        UIView.transition(with: collectionView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.collectionView.reloadData()
        }, completion: nil)
        
        delegate?.calendarView(self, didChangeMonth: currentMonth)
    }
    
    @objc private func didTapNextButton() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? Date()
        dates = generateDatesForMonth(date: currentMonth)
        updateMonthLabel()
        
        UIView.transition(with: collectionView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.collectionView.reloadData()
        }, completion: nil)
        
        delegate?.calendarView(self, didChangeMonth: currentMonth)
    }
    
    // MARK: - Private Methods
    private func updateMonthLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMMM"
        formatter.locale = Locale(identifier: "ko_KR") // 영어 표기 (June 2023)
        monthLabel.text = formatter.string(from: currentMonth)
    }
    
    // 한 달의 모든 날짜 생성
    private func generateDatesForMonth(date: Date) -> [Date] {
        var dates = [Date]()
        let calendar = Calendar.current
        
        // 현재 월의 첫날
        let firstDayOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        ) ?? date
        
        // 첫날의 요일 (0: 일요일, 1: 월요일, ..., 6: 토요일)
        let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        // 해당 월의 일수
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count ?? 30
        
        // 전 달의 날짜로 첫 주 채우기
        for i in 0..<weekdayOfFirstDay {
            if let prevDate = calendar.date(byAdding: .day, value: -(weekdayOfFirstDay - i), to: firstDayOfMonth) {
                dates.append(prevDate)
            }
        }
        
        // 이번 달 날짜 추가
        for i in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDayOfMonth) {
                dates.append(date)
            }
        }
        
        // 마지막 주 남은 부분 다음 달로 채우기
        let remainingDays = 7 - (dates.count % 7)
        if remainingDays < 7 {
            for i in 0..<remainingDays {
                if let nextDate = calendar.date(byAdding: .day, value: daysInMonth + i, to: firstDayOfMonth) {
                    dates.append(nextDate)
                }
            }
        }
        
        return dates
    }
    
    // 날짜가 현재 월에 포함되는지 확인
    private func isDateInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dateMonth = calendar.component(.month, from: date)
        let currentMonth = calendar.component(.month, from: self.currentMonth)
        
        return dateMonth == currentMonth
    }
    
    // 날짜에 산책 기록이 있는지 확인
    private func hasWalkRecord(for date: Date) -> Bool {
        let calendar = Calendar.current
        return recordDates.contains(where: { calendar.isDate($0, inSameDayAs: date) })
    }
    
    // 날짜가 선택되었는지 확인
    private func isDateSelected(_ date: Date) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        let calendar = Calendar.current
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension CalendarView: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7 + dates.count // 요일 헤더 + 날짜 수
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CalendarDateCell.identifier,
            for: indexPath
        ) as? CalendarDateCell else {
            return UICollectionViewCell()
        }
        
        // 요일 헤더 (첫 번째 행)
        if indexPath.item < 7 {
            let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
            cell.configureHeader(with: weekdays[indexPath.item])
            return cell
        }
        
        // 날짜 셀
        let dateIndex = indexPath.item - 7
        if dateIndex < dates.count {
            let date = dates[dateIndex]
            let day = Calendar.current.component(.day, from: date)
            let inCurrentMonth = isDateInCurrentMonth(date)
            let hasRecord = hasWalkRecord(for: date)
            let isSelected = isDateSelected(date)
            
            cell.configure(with: day, isSelected: isSelected, hasWalkRecord: hasRecord)
            
            // 현재 월에 포함되지 않는 날짜는 흐리게 표시
            if !inCurrentMonth {
                cell.alpha = 0.3
            } else {
                cell.alpha = 1.0
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 요일 헤더는 선택 불가
        if indexPath.item < 7 {
            return
        }
        
        let dateIndex = indexPath.item - 7
        if dateIndex < dates.count {
            let date = dates[dateIndex]
            
            // 현재 월에 포함되지 않는 날짜는 선택 불가
            if !isDateInCurrentMonth(date) {
                return
            }
            
            // 이미 선택된 날짜를 다시 탭하면 선택 해제
            if isDateSelected(date) {
                selectedDate = nil
            } else {
                selectedDate = date
            }
            
            collectionView.reloadData()
            delegate?.calendarView(self, didSelectDate: selectedDate)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CalendarView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 7
        let height: CGFloat = indexPath.item < 7 ? 30 : width // 요일 헤더는 더 작게
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

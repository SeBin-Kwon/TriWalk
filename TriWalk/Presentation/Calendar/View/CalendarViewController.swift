//
//  CalendarViewController.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/8/25.
//

import UIKit
import Combine
import SnapKit

final class CalendarViewController: BaseViewController {
    
    // MARK: - Properties
    private let viewModel: CalendarViewModel
    private let viewDidAppearSubject = PassthroughSubject<Void, Never>()
    private let dateSelectionSubject = PassthroughSubject<Date?, Never>()
    private let monthChangedSubject = PassthroughSubject<Date, Never>()
    private let sortOrderSubject = PassthroughSubject<SortOrder, Never>()
    
    // MARK: - UI Components
    private let sortButtonGroup = SortButtonGroup()
    private let sortButtonContainer = UIView()
    
    private let calendarView = CalendarView()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(WalkRecordCell.self, forCellReuseIdentifier: WalkRecordCell.identifier)
        return tableView
    }()
    
    private let emptyStateView: EmptyStateView = {
        let view = EmptyStateView(
            icon: .calendar,
            title: "산책 기록이 없어요",
            message: "새로운 산책을 시작해보세요!"
        )
        view.isHidden = true
        return view
    }()
    
    // MARK: - Initialization
    init(viewModel: CalendarViewModel = CalendarViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        // 캘린더 뷰 델리게이트 설정
        calendarView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearSubject.send(())
    }
    
    // MARK: - Setup
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func configureHierarchy() {
        view.addSubviews(calendarView, sortButtonContainer, tableView, emptyStateView)
    }
    
    override func configureLayout() {
        calendarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview().inset(Spacing.screenMargin)
            make.height.equalTo(300) // 캘린더 뷰 높이 조정
        }
        
        sortButtonContainer.snp.makeConstraints { make in
            make.top.equalTo(calendarView.snp.bottom).offset(Spacing.m)
            make.leading.trailing.equalToSuperview().inset(Spacing.screenMargin)
            make.height.equalTo(40)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(sortButtonContainer.snp.bottom).offset(Spacing.l)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        emptyStateView.snp.makeConstraints { make in
            make.center.equalTo(tableView)
            make.leading.trailing.equalToSuperview().inset(Spacing.screenMargin)
        }
    }
    
    override func configureView() {
        sortButtonGroup.addToView(sortButtonContainer)
        sortButtonGroup.selectedPublisher
            .sink { [weak self] sortOrder in
                self?.sortOrderSubject.send(sortOrder)
            }
            .store(in: &cancellables)
    }
    
    override func bindViewModel() {
        // Input 구성
        let input = CalendarViewModel.Input(
            viewDidAppear: viewDidAppearSubject.eraseToAnyPublisher(),
            dateSelection: dateSelectionSubject.eraseToAnyPublisher(),
            monthChanged: monthChangedSubject.eraseToAnyPublisher(),
            sortOrderChanged: sortOrderSubject.eraseToAnyPublisher()
        )
        
        // ViewModel 변환
        let output = viewModel.transform(input: input)
        
        // 산책 기록 바인딩
        output.walkRecords
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, records in
                owner.tableView.reloadData()
                owner.emptyStateView.isHidden = !records.isEmpty
            }
            .store(in: &cancellables)
        
        // 캘린더 날짜 바인딩
        output.calendarData
            .receive(on: RunLoop.main)
            .withUnretained(self)
            .sink { owner, data in
                owner.calendarView.configure(
                    with: data.currentMonth,
                    recordDates: data.walkDates
                )
                
                // 선택 날짜 설정
                if let selectedDate = data.selectedDate {
                    owner.calendarView.setSelectedDate(selectedDate)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - CalendarViewDelegate
extension CalendarViewController: CalendarViewDelegate {
    func calendarView(_ calendarView: CalendarView, didSelectDate date: Date?) {
        dateSelectionSubject.send(date)
    }
    
    func calendarView(_ calendarView: CalendarView, didChangeMonth date: Date) {
        monthChangedSubject.send(date)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension CalendarViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.walkRecords.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: WalkRecordCell.identifier,
            for: indexPath
        ) as? WalkRecordCell else {
            return UITableViewCell()
        }
        
        let record = viewModel.walkRecords[indexPath.row]
        cell.configure(with: record)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 상세 페이지로 이동
        let record = viewModel.walkRecords[indexPath.row]
        let detailVC = WalkDetailViewController(walkId: record.id)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

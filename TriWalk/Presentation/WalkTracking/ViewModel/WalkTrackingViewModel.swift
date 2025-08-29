//
//  WalkTrackingViewModel.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/31/25.
//

import Foundation
import CoreLocation
import CoreMotion
import Combine
import WidgetKit

enum PermissionStatus {
    case locationDenied
    case motionDenied
    case backgroundLocationDenied
    case allGranted
}

final class WalkTrackingViewModel: BaseViewModel, ViewModelType {
    
    // MARK: - Input-Output 정의
    struct Input {
        let viewDidAppear: AnyPublisher<Void, Never>
        let pauseButtonTapped: AnyPublisher<Void, Never>
        let finishButtonTapped: AnyPublisher<Void, Never>
        let addPhotoButtonTapped: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let stepsCount: AnyPublisher<Int, Never>
        let distance: AnyPublisher<Double, Never>  // km 단위
        let calories: AnyPublisher<Double, Never>  // kcal 단위
        let time: AnyPublisher<TimeInterval, Never>  // 초 단위
        let isPaused: AnyPublisher<Bool, Never>
        let walkRecord: AnyPublisher<WalkRecord, Never>
        let permissionStatus: AnyPublisher<PermissionStatus, Never>
        let showFinishAlert: AnyPublisher<Void, Never>
    }
    
    // MARK: - Private Subjects
    private let stepsCountSubject = CurrentValueSubject<Int, Never>(0)
    private let distanceSubject = CurrentValueSubject<Double, Never>(0.0)
    private let caloriesSubject = CurrentValueSubject<Double, Never>(0.0)
    private let timeSubject = CurrentValueSubject<TimeInterval, Never>(0.0)
    private let isPausedSubject = CurrentValueSubject<Bool, Never>(false)
    private let walkRecordSubject = PassthroughSubject<WalkRecord, Never>()
    
    // MARK: - Private Properties
    private let pedometer = CMPedometer()
    private var locationManager = LocationManager.shared
    private var startDate: Date?
    private var timer: Timer?
    private var accumulatedTime: TimeInterval = 0
    private var previousSteps: Int = 0
    private var previousDistance: Double = 0
    private var previousRouteCoordinates: [CLLocationCoordinate2D] = []
    private var startAddress: String?
    private var destinationAddress: String?
    private var tripType: TripType = .roundTrip
    private let walkRepository: WalkRepositoryProtocol
    // 사용자 정보 (칼로리 계산에 필요)
    private let userWeight: Double = 60.0
    private var savedWalkRecord: WalkRecord?
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var lastStartLocationLookup: Bool = false
    private let permissionsSubject = PassthroughSubject<PermissionStatus, Never>()
    private let showFinishAlertSubject = PassthroughSubject<Void, Never>()
    // 모션 활동 관련 속성
    private var currentActivity: CMMotionActivity?
    private var isAutomaticallyPaused: Bool = false
    private var autoPauseTimer: Timer?
    private let stationaryThreshold: TimeInterval = 300 // 5분
    
    // MARK: - Initialization
    init(walkRepository: WalkRepositoryProtocol = WalkRepository()) {
        self.walkRepository = walkRepository
        super.init()
        setupLocationTracking()
        setupMotionActivityTracking()
        setupBackgroundNotifications()
    }
    
    deinit {
        stopTracking()
    }
    
    // MARK: - Public Methods
    func transform(input: Input) -> Output {
        // 화면이 나타나면 트래킹 시작
        input.viewDidAppear
            .withUnretained(self)
            .sink { owner, _ in
                owner.startTracking()
            }
            .store(in: &cancellables)
        
        // 일시정지/재개 버튼
        input.pauseButtonTapped
            .withUnretained(self)
            .sink { owner, _ in
                owner.togglePause()
            }
            .store(in: &cancellables)
        
        // 종료 버튼
        let finishTrigger = input.finishButtonTapped
            .map { _ in () }
            .eraseToAnyPublisher()
        
        finishTrigger
            .subscribe(showFinishAlertSubject)
            .store(in: &cancellables)
        
//        let walkRecord = walkRecordSubject
//            .eraseToAnyPublisher()
        
        return Output(
            stepsCount: stepsCountSubject.eraseToAnyPublisher(),
            distance: distanceSubject.eraseToAnyPublisher(),
            calories: caloriesSubject.eraseToAnyPublisher(),
            time: timeSubject.eraseToAnyPublisher(),
            isPaused: isPausedSubject.eraseToAnyPublisher(),
            walkRecord: walkRecordSubject.eraseToAnyPublisher(),
            permissionStatus: permissionsSubject.eraseToAnyPublisher(),
            showFinishAlert: showFinishAlertSubject.eraseToAnyPublisher()
        )
    }
    
    private func setupBackgroundNotifications() {
        // 앱이 백그라운드로 진입할 때
        NotificationCenterManager.didEnterBackground.publisher()
            .withUnretained(self)
            .sink { owner, _ in
                if owner.startDate != nil && !owner.isPausedSubject.value {
                    print("앱이 백그라운드로 진입: 위치 추적 계속 유지")
                    // 위치 업데이트 계속 유지하기 위한 설정
                    LocationManager.shared.enableBackgroundLocationUpdates(true)
                }
            }
            .store(in: &cancellables)
        
        // 앱이 포그라운드로 복귀할 때
        NotificationCenterManager.willEnterForeground.publisher()
            .withUnretained(self)
            .sink { owner, _ in
                print("앱이 포그라운드로 복귀")
                // 현재 추적 중인 경우에만 처리
                if owner.startDate != nil && !owner.isPausedSubject.value {
                    print("산책 중 상태로 포그라운드 복귀")
                    LocationManager.shared.enableBackgroundLocationUpdates(false)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func checkPermissions() {
        let locationAuth = LocationManager.shared.authorizationStatus
        let motionAvailable = CMPedometer.isStepCountingAvailable() && CMMotionActivityManager.isActivityAvailable()
        
        if locationAuth == .denied || locationAuth == .restricted {
            permissionsSubject.send(.locationDenied)
        } else if !motionAvailable {
            permissionsSubject.send(.motionDenied)
        } else if locationAuth != .authorizedAlways {
            permissionsSubject.send(.backgroundLocationDenied)
        } else {
            permissionsSubject.send(.allGranted)
        }
    }
    
    private func setupLocationTracking() {
        // 위치 업데이트 구독
        locationManager.locationPublisher
                    .catch { error -> Empty<CLLocation, Never> in
                        print("위치 서비스 오류: \(error.localizedDescription)")
                        return Empty()
                    }
                    .sink { [weak self] location in
                        guard let self = self, !self.isPausedSubject.value else { return }
                        
                        // 첫 위치 기록 및 출발 주소 조회 (최초 1회만)
                        if self.startDate != nil && !self.lastStartLocationLookup {
                            self.lastStartLocationLookup = true
                            
                            // 출발 주소 조회 (역지오코딩 - 산책 시작시 1회만)
                            if self.startAddress == nil {
                                self.lookupStartAddress(at: location.coordinate)
                            }
                        }
                        
                        // 위치 업데이트 처리 - 주소 조회 없이 경로만 업데이트
                        self.updateRoute(with: location)
                        self.updateDistance(with: location)
                    }
                    .store(in: &cancellables)
    }
    
    private func setupMotionActivityTracking() {
        // 모션 활동 상태 구독
        locationManager.motionActivityPublisher
            .sink { [weak self] activity in
                guard let self = self, let activity = activity else { return }
                
                self.currentActivity = activity
                self.handleActivityChange(activity)
            }
            .store(in: &cancellables)
    }
    
    private func handleActivityChange(_ activity: CMMotionActivity) {
        // 신뢰도가 낮으면 무시
        guard activity.confidence == .high || activity.confidence == .medium else {
            return
        }
        
        if activity.automotive && startDate != nil && !isPausedSubject.value {
            // 차량 탑승 감지 시 자동 일시정지 제안
            print("차량 이동 감지 - 산책 자동 일시정지 제안")
            showFinishAlertSubject.send()
        } else if activity.stationary && startDate != nil && !isPausedSubject.value {
            // 정적 상태 감지 - 자동 일시정지 타이머 시작
            startAutoPauseTimer()
        } else if (activity.walking || activity.running) && isAutomaticallyPaused {
            // 다시 걷기 시작하면 자동 재개
            resumeFromAutoPause()
        }
    }
    
    private func startAutoPauseTimer() {
        autoPauseTimer?.invalidate()
        autoPauseTimer = Timer.scheduledTimer(withTimeInterval: stationaryThreshold, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            if let activity = self.currentActivity, activity.stationary && !self.isPausedSubject.value {
                print("장시간 정적 상태로 산책 자동 일시정지")
                self.isAutomaticallyPaused = true
                self.togglePause()
            }
        }
    }
    
    private func resumeFromAutoPause() {
        guard isAutomaticallyPaused else { return }
        
        print("활동 감지로 산책 자동 재개")
        isAutomaticallyPaused = false
        autoPauseTimer?.invalidate()
        
        if isPausedSubject.value {
            togglePause()
        }
    }
    
    // 출발 위치 주소 조회 (최초 1회만 실행)
        private func lookupStartAddress(at coordinate: CLLocationCoordinate2D) {
            locationManager.lookupAddress(for: coordinate) { [weak self] address in
                if let address = address {
                    self?.startAddress = address
                    print("출발 주소 확인: \(address)")
                }
            }
        }
        
        // 도착 위치 주소 조회 (산책 종료 시 1회만 실행)
        private func lookupEndAddress(at coordinate: CLLocationCoordinate2D, completion: @escaping () -> Void) {
            locationManager.lookupAddress(for: coordinate) { [weak self] address in
                if let address = address {
                    self?.destinationAddress = address
                    print("도착 주소 확인: \(address)")
                }
                completion()
            }
        }
    
    // 새로운 메서드 추가
    private func updateRoute(with location: CLLocation) {
        // 경로 좌표 배열에 새 위치 추가
        let newCoordinate = location.coordinate
        self.routeCoordinates.append(newCoordinate)
        print("경로 좌표 추가됨: 현재 좌표 수 = \(self.routeCoordinates.count)")
        
        // previousRouteCoordinates 업데이트 (finishTracking에서 사용)
        self.previousRouteCoordinates = self.routeCoordinates
    }
    
    private func startTracking() {
        guard startDate == nil else { return }  // 이미 시작된 경우 중복 실행 방지
        
        startDate = Date()
        isPausedSubject.send(false)
        
        // Motion Activity 추적 시작
        locationManager.startMotionActivityTracking()
        
        // 타이머 시작
        startTimer()
        
        // 만보계 시작
        startPedometer()
        
        // 위치 추적 시작
        locationManager.startUpdatingLocation()
    }
    
    private func stopTracking() {
        timer?.invalidate()
        timer = nil
        
        pedometer.stopUpdates()
        locationManager.stopUpdatingLocation()
        
        // Motion Activity 추적 중지
        locationManager.stopMotionActivityTracking()
        
        // 자동 일시정지 타이머도 정리
        autoPauseTimer?.invalidate()
        autoPauseTimer = nil
    }
    
    private func togglePause() {
        let isPaused = !isPausedSubject.value
        isPausedSubject.send(isPaused)
        
        if isPaused {
            // 일시정지 처리
            timer?.invalidate()
            timer = nil
            pedometer.stopUpdates()
            locationManager.stopUpdatingLocation()
            
            // 현재까지의 값 저장
            accumulatedTime = timeSubject.value
            previousSteps = stepsCountSubject.value
            previousDistance = distanceSubject.value
        } else {
            // 재개 처리
            startTimer()
            startPedometer()
            locationManager.startUpdatingLocation()
        }
    }
    
    func setWalkInfo(startAddress: String?, destinationAddress: String?, tripType: TripType) {
        self.startAddress = startAddress
        self.destinationAddress = destinationAddress
        self.tripType = tripType
    }
    
    // 종료 및 저장 로직
    func finishTracking(with photos: [CapturedPhoto]) {
        stopTracking()
        
        // 산책 종료 시간 기록
        let endDate = Date()
        
        // 산책 데이터 생성
        let walkRecord = WalkRecord()
        walkRecord.date = startDate ?? Date()  // 산책한 날짜
        walkRecord.startTime = startDate ?? Date()  // 산책 시작 시간
        walkRecord.endTime = endDate  // 산책 종료 시간
        walkRecord.steps = stepsCountSubject.value
        walkRecord.distance = distanceSubject.value
        walkRecord.calories = caloriesSubject.value
        walkRecord.duration = timeSubject.value
        walkRecord.setRandomTicketColor()
        
        // 날씨 정보 추가 (새로 추가된 부분)
        if let weatherData = WeatherManager.shared.currentWeatherData {
            walkRecord.temperature = weatherData.temperature
            walkRecord.weatherType = weatherData.weatherType
            walkRecord.dustGrade = weatherData.dustGrade
        }
        
        // 경로 좌표 상태 확인
        print("저장할 경로 좌표 수: \(routeCoordinates.count)")
        print("previousRouteCoordinates 수: \(previousRouteCoordinates.count)")
        
        if routeCoordinates.isEmpty && !previousRouteCoordinates.isEmpty {
            print("routeCoordinates가 비어있어 previousRouteCoordinates를 사용합니다")
        }
        
        // 최종 경로 데이터 설정 (둘 중 더 많은 좌표가 있는 배열 사용)
        let finalRouteCoordinates = routeCoordinates.count > previousRouteCoordinates.count ?
                                    routeCoordinates : previousRouteCoordinates
        
        // 데이터 저장 (주소 및 이동 방식 정보 포함)
        walkRepository.saveWalk(
            walkRecord,
            photos: photos, // 사진
            routeCoordinates: finalRouteCoordinates,
            startAddress: startAddress,
            destinationAddress: destinationAddress,
            tripType: tripType.rawValue
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("산책 데이터 저장 실패: \(error.localizedDescription)")
            }
        }, receiveValue: { [weak self] savedRecord in
            self?.savedWalkRecord = savedRecord
            self?.walkRecordSubject.send(savedRecord)
            print("산책 데이터가 성공적으로 저장되었습니다.")
            print("저장된 경로 좌표 수: \(savedRecord.loadCoordinates().count)")
        })
        .store(in: &cancellables)
        
        updateWidgetData(with: walkRecord)
    }
    
    // 산책 완료 시 위젯 데이터 업데이트
    private func updateWidgetData(with walkRecord: WalkRecord) {
        let todaySummary = WalkTodaySummary(
            date: Date(),
            distance: walkRecord.distance,
            steps: walkRecord.steps,
            duration: walkRecord.duration,
            isWalkToday: true
        )
        print("위젯 데이터 업데이트: \(todaySummary)")
        WidgetDataManager.updateTodayWalkSummary(with: todaySummary)
        WidgetCenter.shared.reloadTimelines(ofKind: "TriWalkWidget")
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if !self.isPausedSubject.value {
                let newTime = self.accumulatedTime + 1.0
                self.timeSubject.send(newTime)
                self.accumulatedTime = newTime
            }
        }
    }
    
    func startPedometer() {
        // 현재 날짜 기준 또는 마지막으로 일시정지한 시점부터
        let fromDate = isPausedSubject.value ? Date() : (startDate ?? Date())
        
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: fromDate) { [weak self] data, error in
                guard let self = self else { return }
                
                // 권한 오류 확인
                if let error = error as NSError? {
                    if error.code == CMErrorMotionActivityNotAuthorized.rawValue {
                        print("동작 및 피트니스 권한이 없습니다.")
                        // 메인 쓰레드에서 에러 메시지 표시
                        DispatchQueue.main.async {
                            self.permissionsSubject.send(.motionDenied)
                        }
                    } else {
                        print("만보계 오류: \(error.localizedDescription)")
                    }
                    return
                }
                
                // 정상 데이터 처리
                if let data = data {
                    // 활동 상태 필터링 적용
                    if self.shouldFilterPedometerData() {
                        print("비보행 활동 중으로 걸음 수 데이터 필터링")
                        return
                    }
                    
                    // 이전 단계에서 축적된 걸음 수 + 현재 걸음 수
                    let totalSteps = self.previousSteps + (data.numberOfSteps.intValue)
                    self.stepsCountSubject.send(totalSteps)
                    
                    // 거리도 업데이트 (만보계의 거리 정보 활용)
                    if let distanceValue = data.distance?.doubleValue {
                        // 미터 -> 킬로미터로 변환하고 이전 거리에 더함
                        let distanceInKm = (distanceValue / 1000.0) + self.previousDistance
                        self.distanceSubject.send(distanceInKm)
                        
                        // 칼로리 계산도 업데이트
                        self.calculateCalories()
                    }
                }
            }
        } else {
            print("이 기기에서는 걸음 수 측정을 사용할 수 없습니다.")
        }
    }
    
    private func shouldFilterPedometerData() -> Bool {
        guard let activity = currentActivity else {
            return false
        }
        
        // 신뢰도가 높은 경우에만 필터링 적용
        guard activity.confidence == .high else {
            return false
        }
        
        // 차량, 자전거 등 비보행 활동 시 걸음 수 데이터 필터링
        return activity.automotive || activity.cycling
    }
    
    private func updateDistance(with location: CLLocation) {
        // 활동 상태 기반 위치 데이터 필터링
        if shouldFilterLocationData() {
            print("비보행 활동 중으로 위치 기반 거리 계산 제외")
            return
        }
        
        // 위치 데이터로 거리 계산하는 로직
        // (CMPedometer에서 이미 거리를 계산해주므로, 여기서는 필요한 경우만 보정)
    }
    
    private func shouldFilterLocationData() -> Bool {
        guard let activity = currentActivity else {
            return false
        }
        
        // 신뢰도가 높고 차량 이동 중일 때 위치 데이터 필터링
        return activity.confidence == .high && activity.automotive
    }
    
    private func calculateCalories() {
        // 활동 강도에 따른 METs 값 적용
        let mets = getActivityMETs()
        
        // 기존 계산 방식 유지하되 활동 강도 반영
        let distanceCalories = distanceSubject.value * 60.0 * (mets / 3.5)
        let stepsCalories = Double(stepsCountSubject.value) * 0.05 * (mets / 3.5)
        let caloriesBurned = max(distanceCalories, stepsCalories)

        if caloriesBurned < 1.0 && (distanceSubject.value < 0.01 || stepsCountSubject.value < 10) {
            caloriesSubject.send(0.0)
        } else {
            caloriesSubject.send(caloriesBurned)
        }
        print("칼로리 계산 (METs: \(mets)): \(caloriesBurned)")
    }
    
    private func getActivityMETs() -> Double {
        guard let activity = currentActivity, activity.confidence == .high else {
            return 3.5 // 기본 걷기 값
        }
        
        if activity.running {
            return 8.0 // 달리기
        } else if activity.walking {
            return 3.5 // 걷기
        } else {
            return 3.5 // 기본값
        }
    }
}

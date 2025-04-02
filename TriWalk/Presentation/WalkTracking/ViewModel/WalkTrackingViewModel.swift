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
        let isFinished: AnyPublisher<Bool, Never>
    }
    
    // MARK: - Private Subjects
    private let stepsCountSubject = CurrentValueSubject<Int, Never>(0)
    private let distanceSubject = CurrentValueSubject<Double, Never>(0.0)
    private let caloriesSubject = CurrentValueSubject<Double, Never>(0.0)
    private let timeSubject = CurrentValueSubject<TimeInterval, Never>(0.0)
    private let isPausedSubject = CurrentValueSubject<Bool, Never>(false)
    private let isFinishedSubject = CurrentValueSubject<Bool, Never>(false)
    
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
    private let walkRepository: WalkRepositoryProtocol = WalkRepository()
    // 사용자 정보 (칼로리 계산에 필요)
    private let userWeight: Double = 70.0  // kg 단위, 기본값 (나중에 설정에서 변경 가능하게 만들 수 있음)
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationTracking()
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
        input.finishButtonTapped
            .withUnretained(self)
            .sink { owner, _ in
                owner.finishTracking()
            }
            .store(in: &cancellables)
        
        return Output(
            stepsCount: stepsCountSubject.eraseToAnyPublisher(),
            distance: distanceSubject.eraseToAnyPublisher(),
            calories: caloriesSubject.eraseToAnyPublisher(),
            time: timeSubject.eraseToAnyPublisher(),
            isPaused: isPausedSubject.eraseToAnyPublisher(),
            isFinished: isFinishedSubject.eraseToAnyPublisher()
        )
    }
    
    // MARK: - Private Methods
    private func setupLocationTracking() {
        // 위치 업데이트 구독
        locationManager.locationPublisher
            .catch { error -> Empty<CLLocation, Never> in
                print("위치 서비스 오류: \(error.localizedDescription)")
                return Empty()
            }
            .sink { [weak self] location in
                self?.updateDistance(with: location)
            }
            .store(in: &cancellables)
    }
    
    private func startTracking() {
        guard startDate == nil else { return }  // 이미 시작된 경우 중복 실행 방지
        
        startDate = Date()
        isPausedSubject.send(false)
        
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
    private func finishTracking() {
        stopTracking()
        isFinishedSubject.send(true)
        
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
        
        // 데이터 저장 (주소 및 이동 방식 정보 포함)
        walkRepository.saveWalk(
            walkRecord,
            photos: [], // 사진 기능 미룸
            routeCoordinates: previousRouteCoordinates,
            startAddress: startAddress,
            destinationAddress: destinationAddress,
            tripType: tripType.rawValue
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("산책 데이터 저장 실패: \(error.localizedDescription)")
            }
        }, receiveValue: { _ in
            print("산책 데이터가 성공적으로 저장되었습니다.")
        })
        .store(in: &cancellables)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let newTime = self.accumulatedTime + 1.0
            self.timeSubject.send(newTime)
            self.accumulatedTime = newTime
            
            // 시간에 따른 칼로리 계산 (업데이트)
            self.calculateCalories()
        }
    }
    
    private func startPedometer() {
        // 현재 날짜 기준 또는 마지막으로 일시정지한 시점부터
        let fromDate = isPausedSubject.value ? Date() : (startDate ?? Date())
        
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: fromDate) { [weak self] data, error in
                guard let self = self, let data = data, error == nil else {
                    print("만보계 오류: \(error?.localizedDescription ?? "알 수 없는 오류")")
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
        } else {
            print("이 기기에서는 걸음 수 측정을 사용할 수 없습니다.")
        }
    }
    
    private func updateDistance(with location: CLLocation) {
        // 위치 데이터로 거리 계산하는 로직
        // (CMPedometer에서 이미 거리를 계산해주므로, 여기서는 필요한 경우만 보정)
    }
    
    private func calculateCalories() {
        // MET(Metabolic Equivalent of Task) 값 사용
        // 걷기의 MET 값은 대략 3.5 ~ 4.0 정도
        let walkingMET = 3.8
        
        // 칼로리 = MET * 몸무게(kg) * 시간(시간)
        let timeInHours = timeSubject.value / 3600.0
        let caloriesBurned = walkingMET * userWeight * timeInHours
        
        caloriesSubject.send(caloriesBurned)
    }
}

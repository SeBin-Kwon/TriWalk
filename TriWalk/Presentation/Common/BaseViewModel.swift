//
//  BaseViewModel.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/27/25.
//

import Foundation
import Combine

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}

class BaseViewModel {
    var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.removeAll()
        print("\(type(of: self)) deinited")
        if LocationManager.shared.authorizationStatus == .authorizedWhenInUse ||
            LocationManager.shared.authorizationStatus == .authorizedAlways {
            LocationManager.shared.stopUpdatingLocation()
        }
    }
}

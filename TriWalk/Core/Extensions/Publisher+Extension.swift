//
//  Publisher+Extension.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/28/25.
//

import Foundation
import Combine

extension Publisher {
    func withUnretained<T: AnyObject>(_ object: T) -> AnyPublisher<(T, Output), Failure> {
        map { [weak object] value -> (T, Output)? in
            guard let object = object else { return nil }
            return (object, value)
        }
        .compactMap { $0 }
        .eraseToAnyPublisher()
    }
}

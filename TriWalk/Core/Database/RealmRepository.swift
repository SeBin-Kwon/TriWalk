//
//  RealmRepository.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/2/25.
//

import Foundation
import RealmSwift
import Combine

// Realm 작업에 대한 결과 타입
enum RealmOperationResult<T> {
    case success(T)
    case failure(Error)
}

// Realm 에러 타입
enum RealmError: Error {
    case initializationFailed
    case operationFailed(String)
    case objectNotFound
    case invalidObject
}

// Realm 레포지토리 프로토콜
protocol RealmRepositoryProtocol {
    // 객체 저장
    func save<T: Object>(_ object: T, completion: @escaping (RealmOperationResult<T>) -> Void)
    func save<T: Object>(_ objects: [T], completion: @escaping (RealmOperationResult<[T]>) -> Void)
    
    // 객체 조회
    func fetch<T: Object>(_ type: T.Type) -> Results<T>?
    func fetch<T: Object>(_ type: T.Type, predicate: NSPredicate) -> Results<T>?
    func fetchOne<T: Object>(_ type: T.Type, primaryKey: Any) -> T?
    
    // 객체 업데이트
    func update<T: Object>(_ object: T, completion: @escaping (RealmOperationResult<T>) -> Void)
    
    // 객체 삭제
    func delete<T: Object>(_ object: T, completion: @escaping (RealmOperationResult<Void>) -> Void)
    func delete<T: Object>(_ objects: [T], completion: @escaping (RealmOperationResult<Void>) -> Void)
    func deleteAll<T: Object>(_ type: T.Type, completion: @escaping (RealmOperationResult<Void>) -> Void)
}


class RealmRepository: RealmRepositoryProtocol {
    private var realm: Realm?
    static let shared = RealmRepository()
    
    private init() {
        do {
            realm = try Realm()
            print("Realm 파일 위치: \(Realm.Configuration.defaultConfiguration.fileURL?.path ?? "알 수 없음")")
        } catch {
            print("Realm 초기화 실패: \(error.localizedDescription)")
            realm = nil
        }
    }
    
    // 객체 저장
    func save<T: Object>(_ object: T, completion: @escaping (RealmOperationResult<T>) -> Void) {
        guard let realm = realm else {
            completion(.failure(RealmError.initializationFailed))
            return
        }
        
        do {
            try realm.write {
                realm.add(object)
            }
            completion(.success(object))
        } catch {
            completion(.failure(error))
        }
    }
    
    // 객체 배열 저장
    func save<T: Object>(_ objects: [T], completion: @escaping (RealmOperationResult<[T]>) -> Void) {
        guard let realm = realm else {
            completion(.failure(RealmError.initializationFailed))
            return
        }
        
        do {
            try realm.write {
                realm.add(objects)
            }
            completion(.success(objects))
        } catch {
            completion(.failure(error))
        }
    }
    
    // 객체 조회
    func fetch<T: Object>(_ type: T.Type) -> Results<T>? {
        guard let realm = realm else { return nil }
        return realm.objects(type)
    }
    
    // 조건으로 객체 조회
    func fetch<T: Object>(_ type: T.Type, predicate: NSPredicate) -> Results<T>? {
        guard let realm = realm else { return nil }
        return realm.objects(type).filter(predicate)
    }
    
    // 단일 객체 조회
    func fetchOne<T: Object>(_ type: T.Type, primaryKey: Any) -> T? {
        guard let realm = realm else { return nil }
        return realm.object(ofType: type, forPrimaryKey: primaryKey)
    }
    
    // 객체 업데이트
    func update<T: Object>(_ object: T, completion: @escaping (RealmOperationResult<T>) -> Void) {
        guard let realm = realm else {
            completion(.failure(RealmError.initializationFailed))
            return
        }
        
        do {
            try realm.write {
                realm.add(object, update: .modified)
            }
            completion(.success(object))
        } catch {
            completion(.failure(error))
        }
    }
    
    // 객체 삭제
    func delete<T: Object>(_ object: T, completion: @escaping (RealmOperationResult<Void>) -> Void) {
        guard let realm = realm else {
            completion(.failure(RealmError.initializationFailed))
            return
        }
        
        do {
            try realm.write {
                realm.delete(object)
            }
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    // 객체 배열 삭제
    func delete<T: Object>(_ objects: [T], completion: @escaping (RealmOperationResult<Void>) -> Void) {
        guard let realm = realm else {
            completion(.failure(RealmError.initializationFailed))
            return
        }
        
        do {
            try realm.write {
                realm.delete(objects)
            }
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    // 특정 타입의 모든 객체 삭제
    func deleteAll<T: Object>(_ type: T.Type, completion: @escaping (RealmOperationResult<Void>) -> Void) {
        guard let realm = realm else {
            completion(.failure(RealmError.initializationFailed))
            return
        }
        
        let objects = realm.objects(type)
        
        do {
            try realm.write {
                realm.delete(objects)
            }
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    // 트랜잭션 내에서 실행
    func performTransaction(_ block: @escaping (Realm) -> Void, completion: @escaping (RealmOperationResult<Void>) -> Void) {
        guard let realm = realm else {
            completion(.failure(RealmError.initializationFailed))
            return
        }
        
        do {
            try realm.write {
                block(realm)
            }
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}

// Combine 확장
extension RealmRepository {
    // 저장 Publisher
    func savePublisher<T: Object>(_ object: T) -> AnyPublisher<T, Error> {
        return Future<T, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RealmError.initializationFailed))
                return
            }
            
            self.save(object) { result in
                switch result {
                case .success(let savedObject):
                    promise(.success(savedObject))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // 객체 배열 저장 Publisher
    func savePublisher<T: Object>(_ objects: [T]) -> AnyPublisher<[T], Error> {
        return Future<[T], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RealmError.initializationFailed))
                return
            }
            
            self.save(objects) { result in
                switch result {
                case .success(let savedObjects):
                    promise(.success(savedObjects))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // 업데이트 Publisher
    func updatePublisher<T: Object>(_ object: T) -> AnyPublisher<T, Error> {
        return Future<T, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RealmError.initializationFailed))
                return
            }
            
            self.update(object) { result in
                switch result {
                case .success(let updatedObject):
                    promise(.success(updatedObject))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // 삭제 Publisher
    func deletePublisher<T: Object>(_ object: T) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(RealmError.initializationFailed))
                return
            }
            
            self.delete(object) { result in
                switch result {
                case .success:
                    promise(.success(()))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
}

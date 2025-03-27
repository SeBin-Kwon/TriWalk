//
//  RealmManager.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/27/25.
//

import Foundation
import RealmSwift

final class RealmManager {
    static let shared = RealmManager()
    
    private init() {
        setupRealm()
    }
    
    private func setupRealm() {
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    // 향후 마이그레이션 코드
                }
            }
        )
        
        Realm.Configuration.defaultConfiguration = config
    }
    
    func getRealm() -> Realm? {
        do {
            return try Realm()
        } catch {
            print("Error opening Realm: \(error)")
            return nil
        }
    }
}

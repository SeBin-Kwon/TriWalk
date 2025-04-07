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
            // 스키마 버전을 2로 올립니다
            schemaVersion: 2,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                    // WalkRecord에 날씨 관련 필드 추가를 위한 마이그레이션
                    migration.enumerateObjects(ofType: WalkRecord.className()) { oldObject, newObject in
                        // 새 필드는 기본값으로 설정
                        newObject?["temperature"] = 0
                        newObject?["weatherTypeRaw"] = WeatherType.unknown.rawValue
                        newObject?["dustGradeRaw"] = DustGrade.unknown.rawValue
                    }
                    
                    print("마이그레이션 완료: 날씨 정보 필드 추가")
                }
            }
        )
        
        Realm.Configuration.defaultConfiguration = config
        
        do {
            let _ = try Realm()
            print("Realm 초기화 성공: 스키마 버전 \(config.schemaVersion)")
        } catch {
            print("Realm 초기화 오류: \(error.localizedDescription)")
        }
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

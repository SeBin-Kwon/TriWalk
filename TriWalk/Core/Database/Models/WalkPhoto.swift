//
//  WalkPhoto.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/2/25.
//

import UIKit
import RealmSwift
import CoreLocation

// 산책 중 촬영한 사진 정보를 저장하는 Realm 객체
class WalkPhoto: Object {
    @Persisted(primaryKey: true) var id = UUID().uuidString
    @Persisted var imagePath = ""  // 파일 시스템의 이미지 경로
    @Persisted var captureDate = Date()
    @Persisted var latitude: Double = 0.0
    @Persisted var longitude: Double = 0.0
    @Persisted(originProperty: "photos") var walk: LinkingObjects<WalkRecord>
    
    // 이미지를 파일 시스템에 저장하고 경로 반환
    convenience init(image: UIImage, coordinate: CLLocationCoordinate2D? = nil, captureDate: Date = Date()) {
        self.init()
        
        // 좌표 정보 저장 (있는 경우)
        if let coordinate = coordinate {
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
        }
        self.captureDate = captureDate
        
        // 이미지를 파일 시스템에 저장
        self.imagePath = saveImageToFileSystem(image)
    }
    
    // 이미지를 파일 시스템에 저장하고 경로 반환
    private func saveImageToFileSystem(_ image: UIImage) -> String {
        // 문서 디렉토리 경로 가져오기
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // 이미지 저장 디렉토리 (없으면 생성)
        let imageDirectory = documentsDirectory.appendingPathComponent("WalkPhotos")
        
        if !FileManager.default.fileExists(atPath: imageDirectory.path) {
            try? FileManager.default.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
        }
        
        // 고유 파일명 생성
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = imageDirectory.appendingPathComponent(fileName)
        
        // 이미지를 JPEG로 변환하여 저장
        if let data = image.jpegData(compressionQuality: 0.7) {
            try? data.write(to: fileURL)
            let relativePath = "WalkPhotos/\(fileName)"
            print("이미지 저장 경로: \(fileURL.path), 상대 경로: \(relativePath)")
            return relativePath
        }
        
        return ""
    }
    
    // 파일 시스템에서 이미지 로드
    func getImage() -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(imagePath)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let data = try? Data(contentsOf: fileURL) {
                print("이미지 로드 성공: \(fileURL.path)")
                return UIImage(data: data)
            } else {
                print("데이터 로드 실패: \(fileURL.path)")
            }
        } else {
            print("파일 없음: \(fileURL.path)")
        }
        return nil
    }
    
    // 파일 시스템에서 이미지 삭제
    func deleteImageFile() {
        guard !imagePath.isEmpty else { return }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(imagePath)
        try? FileManager.default.removeItem(at: fileURL)
    }
}

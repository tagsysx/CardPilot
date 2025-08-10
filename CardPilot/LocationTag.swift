//
//  LocationTag.swift
//  CardPilot
//
//  Created by Lei Yang on 12/19/2024.
//

import Foundation
import SwiftData

@Model
final class LocationTag {
    var id: String
    var name: String
    var color: String // 存储颜色名称，如 "blue", "red", "green" 等
    var createdAt: Date
    var usageCount: Int // 使用次数
    
    init(name: String, color: String = "blue") {
        self.id = UUID().uuidString
        self.name = name
        self.color = color
        self.createdAt = Date()
        self.usageCount = 0
    }
    
    // 预定义的颜色选项
    static let availableColors: [String] = [
        "blue", "red", "green", "orange", "purple", "pink", "yellow", "gray"
    ]
    
    // 获取颜色对应的Color
    var displayColor: String {
        return color
    }
    
    // 增加使用次数
    func incrementUsage() {
        usageCount += 1
    }
    
    // 减少使用次数
    func decrementUsage() {
        usageCount = max(0, usageCount - 1)
    }
}

// 标签管理器
class LocationTagManager: ObservableObject {
    @Published var availableTags: [LocationTag] = []
    
    init() {
        loadDefaultTags()
    }
    
    // 加载默认标签
    private func loadDefaultTags() {
        let defaultTags = [
            LocationTag(name: "Home", color: "blue"),
            LocationTag(name: "Office", color: "green"),
            LocationTag(name: "Gym", color: "orange"),
            LocationTag(name: "Store", color: "purple"),
            LocationTag(name: "Restaurant", color: "red"),
            LocationTag(name: "Transport", color: "yellow")
        ]
        
        availableTags = defaultTags
    }
    
    // 添加新标签
    func addTag(name: String, color: String) -> LocationTag {
        let newTag = LocationTag(name: name, color: color)
        availableTags.append(newTag)
        return newTag
    }
    
    // 删除标签
    func removeTag(_ tag: LocationTag) {
        availableTags.removeAll { $0.id == tag.id }
    }
    
    // 更新标签
    func updateTag(_ tag: LocationTag, name: String, color: String) {
        tag.name = name
        tag.color = color
    }
    
    // 根据名称查找标签
    func findTag(by name: String) -> LocationTag? {
        return availableTags.first { $0.name.lowercased() == name.lowercased() }
    }
    
    // 获取最常用的标签
    func getMostUsedTags(limit: Int = 5) -> [LocationTag] {
        return availableTags.sorted { $0.usageCount > $1.usageCount }.prefix(limit).map { $0 }
    }
}

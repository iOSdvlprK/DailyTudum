//
//  TodoItem.swift
//  DailyTudum
//
//  Created by joe on 6/24/26.
//

import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var priority: Int
    var dueDate: Date?
    var createdAt: Date
    var updatedAt: Date

    init(title: String, priority: Int = 0, dueDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.priority = priority
        self.dueDate = dueDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

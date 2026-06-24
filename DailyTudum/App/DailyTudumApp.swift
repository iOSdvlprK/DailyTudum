//
//  DailyTudumApp.swift
//  DailyTudum
//
//  Created by joe on 6/24/26.
//

import SwiftUI
import SwiftData

@main
struct DailyTudumApp: App {
    var body: some Scene {
        WindowGroup {
            MainTodoListView()
        }
        .modelContainer(for: TodoItem.self)
    }
}

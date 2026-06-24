//
//  TodoListViewModel.swift
//  DailyTudum
//
//  Created by joe on 6/24/26.
//

import Foundation
import SwiftData

@Observable
final class TodoListViewModel {
    enum FilterMode: String, CaseIterable {
        case all = "All Tasks"
        case today = "Today"
    }
    var todos: [TodoItem] = []
    var selectedFilter: FilterMode = .all

    var filteredTodos: [TodoItem] {
        switch selectedFilter {
        case .all:
            return todos
        case .today:
            return todos.filter { todo in
                guard let dueDate = todo.dueDate else { return false }
                return Calendar.current.isDateInToday(dueDate)
            }
        }
    }

    func fetchTodos(modelContext: ModelContext) {
        let fetchDescriptor = FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])

        do {
            todos = try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Failed to fetch todos: \(error.localizedDescription)")
        }
    }

    func addTodo(title: String, priority: Int = 0, dueDate: Date? = nil, modelContext: ModelContext) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let todo = TodoItem(title: trimmedTitle, priority: priority, dueDate: dueDate)
        modelContext.insert(todo)

        do {
            try modelContext.save()
            fetchTodos(modelContext: modelContext)
        } catch {
            print("Failed to save todo: \(error.localizedDescription)")
        }
    }

    func toggleTodo(_ todo: TodoItem, modelContext: ModelContext) {
        todo.isCompleted.toggle()
        todo.updatedAt = Date()

        do {
            try modelContext.save()
            fetchTodos(modelContext: modelContext)
        } catch {
            print("Failed to toggle todo: \(error.localizedDescription)")
        }
    }

    func deleteTodo(_ todo: TodoItem, modelContext: ModelContext) {
        modelContext.delete(todo)

        do {
            try modelContext.save()
            fetchTodos(modelContext: modelContext)
        } catch {
            print("Failed to delete todo: \(error.localizedDescription)")
        }
    }
}

//
//  MainTodoListView.swift
//  DailyTudum
//
//  Created by joe on 6/24/26.
//

import SwiftUI
import SwiftData

struct MainTodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TodoListViewModel()
    @State private var newTodoTitle = ""
    @FocusState private var isInputFocused: Bool

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    inlineInputField
                        .padding(.horizontal)
                        .padding(.top, 8)

                    if viewModel.filteredTodos.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.filteredTodos) { todo in
                            todoCard(todo)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("DailyTudum")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        ForEach(TodoListViewModel.FilterMode.allCases, id: \.self) { filter in
                            filterButton(filter)

                            if filter != TodoListViewModel.FilterMode.allCases.last {
                                Spacer()
                            }
                        }
                    }
                }
            }
            .onAppear {
                viewModel.fetchTodos(modelContext: modelContext)
            }
        }
    }

    // MARK: - Inline Input Field

    private var inlineInputField: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField("Add a new task...", text: $newTodoTitle)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($isInputFocused)
                    .onSubmit {
                        addTodo()
                    }

                Button {
                    addTodo()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                }
                .disabled(newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text(viewModel.selectedFilter == .today ? "No tasks due today" : "No tasks yet")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Add a task using the field above")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Todo Card

    private func todoCard(_ todo: TodoItem) -> some View {
        HStack(spacing: 14) {
            Button {
                toggleTodo(todo)
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(todo.isCompleted ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.body)
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)

                if let dueDate = todo.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(dateFormatter.string(from: dueDate))
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if todo.priority > 0 {
                Image(systemName: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteTodo(todo)
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                toggleTodo(todo)
            } label: {
                Label(todo.isCompleted ? "Undo" : "Done", systemImage: todo.isCompleted ? "arrow.uturn.backward" : "checkmark")
            }
            .tint(.green)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                deferToTomorrow(todo)
            } label: {
                Label("Tomorrow", systemImage: "calendar.badge.clock")
            }
            .tint(.blue)
        }
    }

    // MARK: - Filter Button

    private func filterButton(_ filter: TodoListViewModel.FilterMode) -> some View {
        let isSelected = viewModel.selectedFilter == filter

        return Button {
            viewModel.selectedFilter = filter
        } label: {
            Text(filter.rawValue)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.regularMaterial))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func addTodo() {
        let trimmed = newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        viewModel.addTodo(title: trimmed, modelContext: modelContext)
        newTodoTitle = ""
        isInputFocused = false
    }

    private func toggleTodo(_ todo: TodoItem) {
        viewModel.toggleTodo(todo, modelContext: modelContext)
    }

    private func deleteTodo(_ todo: TodoItem) {
        viewModel.deleteTodo(todo, modelContext: modelContext)
    }

    private func deferToTomorrow(_ todo: TodoItem) {
        todo.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        todo.updatedAt = Date()

        do {
            try modelContext.save()
            viewModel.fetchTodos(modelContext: modelContext)
        } catch {
            print("Failed to defer todo: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TodoItem.self, configurations: config)

    let sampleTodos = [
        TodoItem(title: "Review PR feedback", priority: 1),
        TodoItem(title: "Buy groceries", dueDate: Date().addingTimeInterval(86400)),
        TodoItem(title: "Workout at 6pm"),
    ]

    for todo in sampleTodos {
        container.mainContext.insert(todo)
    }

    return MainTodoListView()
        .modelContainer(container)
}

import SwiftUI

// MARK: - Reorderable List

struct ReorderableFieldList: View {
    @Binding var fields: [TemplateField]
    let stepNumber: Int
    let onTap: (TemplateField) -> Void
    let onDelete: (TemplateField) -> Void

    private var stepFields: [TemplateField] {
        fields.filter { $0.stepNumber == stepNumber }.sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            ForEach(stepFields) { field in
                FieldBuilderCard(
                    field: field,
                    onTap: { onTap(field) },
                    onDelete: { onDelete(field) }
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .listRowSeparator(.hidden)
            }
            .onMove { source, destination in
                moveFields(from: source, to: destination)
            }
            .onDelete { indexSet in
                deleteFields(at: indexSet)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
    }

    private func moveFields(from source: IndexSet, to destination: Int) {
        var ordered = stepFields
        ordered.move(fromOffsets: source, toOffset: destination)

        // Update order values
        for (index, field) in ordered.enumerated() {
            if let fieldIndex = fields.firstIndex(where: { $0.id == field.id }) {
                fields[fieldIndex].order = index + 1
            }
        }
    }

    private func deleteFields(at offsets: IndexSet) {
        let toDelete = offsets.map { stepFields[$0] }
        for field in toDelete {
            fields.removeAll { $0.id == field.id }
        }
    }
}

// MARK: - Reorderable Step Tabs

struct ReorderableStepTabs: View {
    @Binding var steps: [TemplateStep]
    @Binding var selectedIndex: Int
    let onAddStep: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    StepTab(
                        step: step,
                        isSelected: selectedIndex == index,
                        onTap: { selectedIndex = index },
                        onRename: { newName in
                            steps[index].name = newName
                        },
                        onDelete: {
                            if steps.count > 1 {
                                steps.remove(at: index)
                                // Renumber steps
                                for i in steps.indices {
                                    steps[i].stepNumber = i + 1
                                }
                                if selectedIndex >= steps.count {
                                    selectedIndex = steps.count - 1
                                }
                            }
                        }
                    )
                }

                Button(action: onAddStep) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FFColors.accentCyan)
                        .frame(width: 32, height: 32)
                        .background(FFColors.surfaceElevated)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(FFColors.border, lineWidth: 1))
                }
                .accessibilityLabel("Add new step")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

struct StepTab: View {
    let step: TemplateStep
    let isSelected: Bool
    let onTap: () -> Void
    let onRename: (String) -> Void
    let onDelete: () -> Void

    @State private var showRename = false
    @State private var newName = ""

    var body: some View {
        Button(action: onTap) {
            Text(step.name)
                .font(FFTypography.bodySmall())
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? FFColors.primaryNavy : FFColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? FFColors.accentCyan : FFColors.surfaceElevated)
                .cornerRadius(20)
        }
        .contextMenu {
            Button {
                newName = step.name
                showRename = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Step", systemImage: "trash")
            }
        }
        .accessibilityLabel("Step \(step.stepNumber): \(step.name)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .alert("Rename Step", isPresented: $showRename) {
            TextField("Step name", text: $newName)
            Button("Save") { onRename(newName) }
            Button("Cancel", role: .cancel) {}
        }
    }
}

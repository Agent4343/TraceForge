import SwiftUI

struct TemplateBuilderScreen: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    let template: Template?

    @State private var templateName: String = ""
    @State private var steps: [TemplateStep] = []
    @State private var fields: [TemplateField] = []
    @State private var selectedStepIndex: Int = 0
    @State private var isPreviewMode = false
    @State private var showFieldTypePicker = false
    @State private var showFieldEditor = false
    @State private var editingField: TemplateField?
    @State private var showRenameAlert = false
    @State private var renameStepIndex: Int = 0
    @State private var renameText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Template name
                    HStack {
                        TextField("", text: $templateName, prompt: Text("Template Name").foregroundColor(FFColors.textSecondary.opacity(0.4)))
                            .font(FFTypography.displaySmall())
                            .foregroundColor(FFColors.textPrimary)

                        Toggle(isPreviewMode ? "Preview" : "Edit", isOn: $isPreviewMode)
                            .toggleStyle(.button)
                            .tint(FFColors.accentCyan)
                            .font(FFTypography.bodySmall())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // Step tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                                Button {
                                    selectedStepIndex = index
                                } label: {
                                    Text(step.name)
                                        .font(FFTypography.bodySmall())
                                        .fontWeight(selectedStepIndex == index ? .semibold : .regular)
                                        .foregroundColor(selectedStepIndex == index ? FFColors.primaryNavy : FFColors.textSecondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedStepIndex == index ? FFColors.accentCyan : FFColors.surfaceElevated)
                                        .cornerRadius(20)
                                }
                                .contextMenu {
                                    Button("Rename") {
                                        renameStepIndex = index
                                        renameText = step.name
                                        showRenameAlert = true
                                    }
                                    Button("Delete", role: .destructive) {
                                        if steps.count > 1 {
                                            steps.remove(at: index)
                                            if selectedStepIndex >= steps.count {
                                                selectedStepIndex = steps.count - 1
                                            }
                                        }
                                    }
                                }
                            }

                            Button {
                                addStep()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(FFColors.accentCyan)
                                    .frame(width: 32, height: 32)
                                    .background(FFColors.surfaceElevated)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(FFColors.border, lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }

                    Divider().background(FFColors.border)

                    // Field list
                    if isPreviewMode {
                        previewContent
                    } else {
                        editorContent
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(FFColors.accentCyan)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .foregroundColor(FFColors.accentCyan)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showFieldTypePicker) {
                FieldTypePickerSheet(onSelect: { type in
                    addField(type: type)
                    showFieldTypePicker = false
                })
            }
            .sheet(isPresented: $showFieldEditor) {
                if let field = editingField {
                    FieldEditorSheet(field: field, onSave: { updatedField in
                        if let index = fields.firstIndex(where: { $0.id == updatedField.id }) {
                            fields[index] = updatedField
                        }
                        showFieldEditor = false
                    })
                }
            }
            .alert("Rename Step", isPresented: $showRenameAlert) {
                TextField("Step name", text: $renameText)
                Button("Cancel", role: .cancel) { }
                Button("Rename") {
                    if steps.indices.contains(renameStepIndex), !renameText.isEmpty {
                        steps[renameStepIndex].name = renameText
                    }
                }
            }
        }
        .onAppear {
            if let template = template {
                templateName = template.name
                steps = template.steps
                fields = template.fields
            } else {
                templateName = ""
                steps = [TemplateStep(stepNumber: 1, name: "Step 1")]
                fields = []
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .duplicateField)) { notification in
            guard let original = notification.object as? TemplateField else { return }
            let duplicate = TemplateField(
                stepNumber: original.stepNumber,
                type: original.type,
                label: "\(original.label) (Copy)",
                required: original.required,
                order: original.order + 1,
                helpText: original.helpText,
                options: original.options,
                minValue: original.minValue,
                maxValue: original.maxValue,
                unit: original.unit,
                maxLength: original.maxLength,
                maxPhotos: original.maxPhotos,
                attestationText: original.attestationText
            )
            fields.append(duplicate)
        }
    }

    // MARK: - Editor Content

    private var editorContent: some View {
        VStack(spacing: 0) {
            let currentStepNumber = steps.indices.contains(selectedStepIndex) ? steps[selectedStepIndex].stepNumber : 1
            let stepFields = fields.filter { $0.stepNumber == currentStepNumber }.sorted { $0.order < $1.order }

            if stepFields.isEmpty {
                EmptyStateView(
                    icon: "plus.rectangle.on.rectangle",
                    title: "No Fields Yet",
                    subtitle: "Add fields to this step to build your form."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(stepFields) { field in
                            FieldBuilderCard(field: field, onTap: {
                                editingField = field
                                showFieldEditor = true
                            }, onDelete: {
                                fields.removeAll { $0.id == field.id }
                            })
                        }
                    }
                    .padding(16)
                }
            }

            // Add field button
            Button {
                showFieldTypePicker = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Field")
                }
                .font(FFTypography.bodyMediumBold())
                .foregroundColor(FFColors.accentCyan)
                .frame(maxWidth: .infinity)
                .frame(minHeight: FFLayout.minTapTarget)
                .background(FFColors.accentCyan.opacity(0.1))
                .cornerRadius(FFLayout.cornerRadius)
            }
            .padding(16)
        }
    }

    // MARK: - Preview Content

    private var previewContent: some View {
        ZStack {
            ScrollView {
                let currentStepNumber = steps.indices.contains(selectedStepIndex) ? steps[selectedStepIndex].stepNumber : 1
                let stepFields = fields.filter { $0.stepNumber == currentStepNumber }.sorted { $0.order < $1.order }

                LazyVStack(spacing: 16) {
                    ForEach(stepFields) { field in
                        FieldRenderer(field: field, value: .constant(""))
                    }
                }
                .padding(16)
            }

            // Watermark
            Text("PREVIEW — Not a live workflow")
                .font(FFTypography.label())
                .foregroundColor(FFColors.warning.opacity(0.5))
                .rotationEffect(.degrees(-30))
                .allowsHitTesting(false)
        }
    }

    // MARK: - Actions

    private func addStep() {
        let newStep = TemplateStep(
            stepNumber: steps.count + 1,
            name: "Step \(steps.count + 1)"
        )
        steps.append(newStep)
        selectedStepIndex = steps.count - 1
    }

    private func addField(type: FieldType) {
        let currentStepNumber = steps.indices.contains(selectedStepIndex) ? steps[selectedStepIndex].stepNumber : 1
        let stepFields = fields.filter { $0.stepNumber == currentStepNumber }
        let newField = TemplateField(
            stepNumber: currentStepNumber,
            type: type,
            label: type.displayName,
            required: false,
            order: stepFields.count + 1
        )
        fields.append(newField)
    }

    private func saveTemplate() {
        if let existing = template {
            if let index = appState.templates.firstIndex(where: { $0.id == existing.id }) {
                appState.templates[index].name = templateName
                appState.templates[index].fields = fields
                appState.templates[index].steps = steps
                appState.templates[index].updatedAt = Date()
                appState.templates[index].version += 1
            }
        } else {
            guard let user = appState.currentUser else { return }
            let newTemplate = Template(
                id: UUID(),
                organizationId: user.organizationId,
                name: templateName,
                status: .draft,
                version: 1,
                fields: fields,
                steps: steps,
                createdBy: user.id,
                createdAt: Date(),
                updatedAt: Date()
            )
            appState.templates.insert(newTemplate, at: 0)
        }
        dismiss()
    }
}

// MARK: - Field Builder Card

struct FieldBuilderCard: View {
    let field: TemplateField
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(FFColors.textSecondary)
                    .frame(width: 20)

                // Type icon
                Image(systemName: field.type.icon)
                    .foregroundColor(FFColors.accentCyan)
                    .frame(width: 24)

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(field.label)
                            .font(FFTypography.bodyMedium())
                            .foregroundColor(FFColors.textPrimary)
                        if field.required {
                            Text("*")
                                .foregroundColor(FFColors.danger)
                        }
                    }
                    Text(field.type.displayName)
                        .font(FFTypography.bodySmall())
                        .foregroundColor(FFColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(FFColors.textSecondary)
                    .font(.system(size: 12))
            }
            .padding(12)
            .background(FFColors.surfaceElevated)
            .cornerRadius(FFLayout.cornerRadiusSmall)
            .overlay(
                RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                    .stroke(FFColors.border, lineWidth: 1)
            )
        }
        .contextMenu {
            Button("Duplicate") {
                NotificationCenter.default.post(name: .duplicateField, object: field)
            }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
}

// MARK: - Field Type Picker

struct FieldTypePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    let onSelect: (FieldType) -> Void

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(FieldType.allCases) { type in
                            Button {
                                onSelect(type)
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(FFColors.accentCyan)
                                        .frame(height: 32)

                                    Text(type.displayName)
                                        .font(FFTypography.bodySmall())
                                        .foregroundColor(FFColors.textPrimary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 100)
                                .background(FFColors.surfaceElevated)
                                .cornerRadius(FFLayout.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: FFLayout.cornerRadius)
                                        .stroke(FFColors.border, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(FFColors.accentCyan)
                }
            }
            .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Field Editor Sheet

struct FieldEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var field: TemplateField
    let onSave: (TemplateField) -> Void

    @State private var optionsText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Label
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Label")
                                .font(FFTypography.bodyMediumBold())
                                .foregroundColor(FFColors.textPrimary)

                            TextField("", text: $field.label, prompt: Text("Field label").foregroundColor(FFColors.textSecondary.opacity(0.4)))
                                .foregroundColor(FFColors.textPrimary)
                                .padding()
                                .background(FFColors.surface)
                                .cornerRadius(FFLayout.cornerRadiusSmall)
                                .overlay(
                                    RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                                        .stroke(FFColors.border, lineWidth: 1)
                                )
                        }

                        // Help text
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Help Text (optional)")
                                .font(FFTypography.bodyMediumBold())
                                .foregroundColor(FFColors.textPrimary)

                            TextField("", text: Binding(
                                get: { field.helpText ?? "" },
                                set: { field.helpText = $0.isEmpty ? nil : $0 }
                            ), prompt: Text("Instructions for the user").foregroundColor(FFColors.textSecondary.opacity(0.4)))
                                .foregroundColor(FFColors.textPrimary)
                                .padding()
                                .background(FFColors.surface)
                                .cornerRadius(FFLayout.cornerRadiusSmall)
                                .overlay(
                                    RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                                        .stroke(FFColors.border, lineWidth: 1)
                                )
                        }

                        // Required toggle
                        Toggle(isOn: $field.required) {
                            Text("Required")
                                .font(FFTypography.bodyMediumBold())
                                .foregroundColor(FFColors.textPrimary)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: FFColors.accentCyan))

                        // Type-specific settings
                        typeSpecificSettings
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Edit Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(FFColors.accentCyan)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { onSave(field) }
                        .foregroundColor(FFColors.accentCyan)
                        .fontWeight(.semibold)
                }
            }
            .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.large])
        .onAppear {
            optionsText = field.options?.joined(separator: "\n") ?? ""
        }
    }

    @ViewBuilder
    private var typeSpecificSettings: some View {
        switch field.type {
        case .text:
            VStack(alignment: .leading, spacing: 6) {
                Text("Max Character Limit")
                    .font(FFTypography.bodyMediumBold())
                    .foregroundColor(FFColors.textPrimary)
                TextField("", text: Binding(
                    get: { field.maxLength.map { String($0) } ?? "" },
                    set: { field.maxLength = Int($0) }
                ))
                .keyboardType(.numberPad)
                .foregroundColor(FFColors.textPrimary)
                .padding()
                .background(FFColors.surface)
                .cornerRadius(FFLayout.cornerRadiusSmall)
                .overlay(RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall).stroke(FFColors.border, lineWidth: 1))
            }

        case .number:
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Min")
                        .font(FFTypography.bodyMediumBold())
                        .foregroundColor(FFColors.textPrimary)
                    TextField("", text: Binding(
                        get: { field.minValue.map { String($0) } ?? "" },
                        set: { field.minValue = Double($0) }
                    ))
                    .keyboardType(.decimalPad)
                    .foregroundColor(FFColors.textPrimary)
                    .padding()
                    .background(FFColors.surface)
                    .cornerRadius(FFLayout.cornerRadiusSmall)
                    .overlay(RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall).stroke(FFColors.border, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Max")
                        .font(FFTypography.bodyMediumBold())
                        .foregroundColor(FFColors.textPrimary)
                    TextField("", text: Binding(
                        get: { field.maxValue.map { String($0) } ?? "" },
                        set: { field.maxValue = Double($0) }
                    ))
                    .keyboardType(.decimalPad)
                    .foregroundColor(FFColors.textPrimary)
                    .padding()
                    .background(FFColors.surface)
                    .cornerRadius(FFLayout.cornerRadiusSmall)
                    .overlay(RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall).stroke(FFColors.border, lineWidth: 1))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Unit Label")
                    .font(FFTypography.bodyMediumBold())
                    .foregroundColor(FFColors.textPrimary)
                TextField("", text: Binding(
                    get: { field.unit ?? "" },
                    set: { field.unit = $0.isEmpty ? nil : $0 }
                ), prompt: Text("e.g., PSI, °C, %LEL").foregroundColor(FFColors.textSecondary.opacity(0.4)))
                .foregroundColor(FFColors.textPrimary)
                .padding()
                .background(FFColors.surface)
                .cornerRadius(FFLayout.cornerRadiusSmall)
                .overlay(RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall).stroke(FFColors.border, lineWidth: 1))
            }

        case .dropdown, .multiSelect:
            VStack(alignment: .leading, spacing: 6) {
                Text("Options (one per line)")
                    .font(FFTypography.bodyMediumBold())
                    .foregroundColor(FFColors.textPrimary)
                TextEditor(text: $optionsText)
                    .foregroundColor(FFColors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(FFColors.surface)
                    .cornerRadius(FFLayout.cornerRadiusSmall)
                    .overlay(RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall).stroke(FFColors.border, lineWidth: 1))
                    .onChange(of: optionsText) { _, newValue in
                        field.options = newValue.split(separator: "\n").map { String($0) }.filter { !$0.isEmpty }
                    }
            }

        case .photo:
            VStack(alignment: .leading, spacing: 6) {
                Text("Max Photos (1-10)")
                    .font(FFTypography.bodyMediumBold())
                    .foregroundColor(FFColors.textPrimary)
                Stepper(value: Binding(
                    get: { field.maxPhotos ?? 3 },
                    set: { field.maxPhotos = $0 }
                ), in: 1...10) {
                    Text("\(field.maxPhotos ?? 3)")
                        .font(FFTypography.bodyLarge())
                        .foregroundColor(FFColors.textPrimary)
                }
                .tint(FFColors.accentCyan)
            }

        case .signature:
            VStack(alignment: .leading, spacing: 6) {
                Text("Attestation Text")
                    .font(FFTypography.bodyMediumBold())
                    .foregroundColor(FFColors.textPrimary)
                TextEditor(text: Binding(
                    get: { field.attestationText ?? "" },
                    set: { field.attestationText = $0.isEmpty ? nil : $0 }
                ))
                .foregroundColor(FFColors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(8)
                .background(FFColors.surface)
                .cornerRadius(FFLayout.cornerRadiusSmall)
                .overlay(RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall).stroke(FFColors.border, lineWidth: 1))
            }

        default:
            EmptyView()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let duplicateField = Notification.Name("FormFlow.duplicateField")
}

#Preview {
    TemplateBuilderScreen(template: MockData.preJobSafetyTemplate)
        .environmentObject(AppState())
}

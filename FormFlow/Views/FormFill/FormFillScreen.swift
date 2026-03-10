import SwiftUI

struct FormFillScreen: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let task: MockData.TaskItem

    @State private var fieldValues: [UUID: String] = [:]
    @State private var saveState: SaveState = .unsaved
    @State private var showSignatureModal = false
    @State private var showHandoverSheet = false
    @State private var showUnsavedAlert = false
    @State private var autoSaveTimer: Timer?

    private var template: Template? {
        appState.templates.first { $0.id == appState.workflows.first(where: { $0.id == task.workflowId })?.templateId }
    }

    private var stepFields: [TemplateField] {
        guard let template = template else { return [] }
        return template.fields
            .filter { $0.stepNumber == task.stepNumber }
            .sorted { $0.order < $1.order }
    }

    private var allRequiredFieldsFilled: Bool {
        stepFields
            .filter { $0.required && $0.type.isInputField }
            .allSatisfy { field in
                let val = fieldValues[field.id] ?? ""
                return !val.isEmpty
            }
    }

    private var workflow: WorkflowInstance? {
        appState.workflows.first { $0.id == task.workflowId }
    }

    enum SaveState {
        case unsaved, saving, saved, offline

        var color: Color {
            switch self {
            case .unsaved: return FFColors.textSecondary
            case .saving: return FFColors.warning
            case .saved: return FFColors.success
            case .offline: return FFColors.warning
            }
        }
    }

    var body: some View {
        ZStack {
            FFColors.primaryNavy.ignoresSafeArea()

            VStack(spacing: 0) {
                // Step progress bar
                if let template = template {
                    StepProgressBar(
                        totalSteps: template.steps.count,
                        completedSteps: task.stepNumber - 1,
                        currentStep: task.stepNumber
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                // Fields
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(stepFields) { field in
                            FieldRenderer(
                                field: field,
                                value: Binding(
                                    get: { fieldValues[field.id] ?? "" },
                                    set: { newValue in
                                        fieldValues[field.id] = newValue
                                        saveState = .unsaved
                                        appState.saveResponse(workflowId: task.workflowId, fieldId: field.id, value: newValue)
                                    }
                                )
                            )
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 100)
                }

                // Bottom action bar
                VStack(spacing: 8) {
                    Divider()
                        .background(FFColors.border)

                    HStack(spacing: 12) {
                        Button("Save Progress") {
                            saveProgress()
                        }
                        .ffSecondaryButton()

                        Button("Complete & Sign Step") {
                            showSignatureModal = true
                        }
                        .ffPrimaryButton(isEnabled: allRequiredFieldsFilled)
                        .disabled(!allRequiredFieldsFilled)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .background(FFColors.primaryNavy)
            }
        }
        .navigationTitle(task.stepName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(saveState.color)
                        .frame(width: 8, height: 8)

                    Menu {
                        Button(action: saveProgress) {
                            Label("Save Now", systemImage: "square.and.arrow.down")
                        }
                        Button(action: { showHandoverSheet = true }) {
                            Label("Transfer Step", systemImage: "arrow.right.arrow.left")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(FFColors.textSecondary)
                    }
                }
            }
        }
        .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(isPresented: $showSignatureModal) {
            StepSignatureModal(
                stepName: task.stepName,
                fieldCount: stepFields.filter { $0.type.isInputField }.count,
                workflowId: task.workflowId,
                stepNumber: task.stepNumber,
                onComplete: {
                    showSignatureModal = false
                    dismiss()
                }
            )
            .environmentObject(appState)
        }
        .sheet(isPresented: $showHandoverSheet) {
            ShiftHandoverScreen(
                stepName: task.stepName,
                workflowName: task.workflowName,
                workflowId: task.workflowId,
                stepNumber: task.stepNumber
            )
            .environmentObject(appState)
        }
        .onAppear {
            loadSavedResponses()
            startAutoSave()
        }
        .onDisappear {
            autoSaveTimer?.invalidate()
        }
    }

    private func loadSavedResponses() {
        for field in stepFields {
            if let val = appState.getResponse(workflowId: task.workflowId, fieldId: field.id) {
                fieldValues[field.id] = val
            }
        }
        saveState = .saved
    }

    private func saveProgress() {
        saveState = .saving
        for (fieldId, value) in fieldValues {
            appState.saveResponse(workflowId: task.workflowId, fieldId: fieldId, value: value)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            saveState = .saved
        }
    }

    private func startAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            if saveState == .unsaved {
                saveProgress()
            }
        }
    }
}

// MARK: - Field Renderer

struct FieldRenderer: View {
    let field: TemplateField
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            if field.type != .divider {
                HStack(spacing: 4) {
                    Text(field.label)
                        .font(FFTypography.bodyMediumBold())
                        .foregroundColor(FFColors.textPrimary)
                    if field.required {
                        Text("*")
                            .foregroundColor(FFColors.danger)
                    }
                }

                if let helpText = field.helpText {
                    Text(helpText)
                        .font(FFTypography.bodySmall())
                        .foregroundColor(FFColors.textSecondary)
                }
            }

            // Field input
            fieldInput
        }
        .ffCard()
    }

    @ViewBuilder
    private var fieldInput: some View {
        switch field.type {
        case .text:
            TextFieldInput(value: $value, maxLength: field.maxLength)
        case .longText:
            LongTextInput(value: $value)
        case .number:
            NumberFieldInput(value: $value, min: field.minValue, max: field.maxValue, unit: field.unit)
        case .yesNo:
            YesNoInput(value: $value)
        case .dropdown:
            DropdownInput(value: $value, options: field.options ?? [])
        case .multiSelect:
            MultiSelectInput(value: $value, options: field.options ?? [])
        case .date:
            DateInput(value: $value, includeTime: false)
        case .dateTime:
            DateInput(value: $value, includeTime: true)
        case .photo:
            EnhancedPhotoInput(value: $value, maxPhotos: field.maxPhotos ?? 3, requireAnnotation: field.requireAnnotation ?? false)
        case .signature:
            SignatureFieldInput(value: $value, attestationText: field.attestationText)
        case .divider:
            Divider()
                .background(FFColors.border)
                .padding(.vertical, 4)
        case .infoText:
            Text(field.label)
                .font(FFTypography.bodyMedium())
                .foregroundColor(FFColors.textSecondary)
                .italic()
        }
    }
}

// MARK: - Field Inputs

struct TextFieldInput: View {
    @Binding var value: String
    var maxLength: Int?

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            TextField("", text: $value, prompt: Text("Enter text").foregroundColor(FFColors.textSecondary.opacity(0.4)))
                .foregroundColor(FFColors.textPrimary)
                .padding()
                .frame(minHeight: FFLayout.minTapTarget)
                .background(FFColors.surface)
                .cornerRadius(FFLayout.cornerRadiusSmall)
                .overlay(
                    RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                        .stroke(FFColors.border, lineWidth: 1)
                )

            if let max = maxLength {
                Text("\(value.count)/\(max)")
                    .font(FFTypography.monoSmall())
                    .foregroundColor(value.count > max ? FFColors.danger : FFColors.textSecondary)
            }
        }
    }
}

struct LongTextInput: View {
    @Binding var value: String

    var body: some View {
        TextEditor(text: $value)
            .foregroundColor(FFColors.textPrimary)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 100)
            .padding(8)
            .background(FFColors.surface)
            .cornerRadius(FFLayout.cornerRadiusSmall)
            .overlay(
                RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                    .stroke(FFColors.border, lineWidth: 1)
            )
    }
}

struct NumberFieldInput: View {
    @Binding var value: String
    var min: Double?
    var max: Double?
    var unit: String?

    private var numericValue: Double? { Double(value) }
    private var isOutOfRange: Bool {
        guard let num = numericValue else { return false }
        if let min = min, num < min { return true }
        if let max = max, num > max { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("", text: $value, prompt: Text("0").foregroundColor(FFColors.textSecondary.opacity(0.4)))
                    .keyboardType(.decimalPad)
                    .foregroundColor(FFColors.textPrimary)

                if let unit = unit {
                    Text(unit)
                        .font(FFTypography.bodyMedium())
                        .foregroundColor(FFColors.textSecondary)
                }
            }
            .padding()
            .frame(minHeight: FFLayout.minTapTarget)
            .background(FFColors.surface)
            .cornerRadius(FFLayout.cornerRadiusSmall)
            .overlay(
                RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                    .stroke(isOutOfRange ? FFColors.warning : FFColors.border, lineWidth: 1)
            )

            if isOutOfRange {
                if let min = min, let max = max {
                    Text("Value must be between \(String(format: "%.1f", min)) and \(String(format: "%.1f", max))\(unit.map { " \($0)" } ?? "")")
                        .font(FFTypography.bodySmall())
                        .foregroundColor(FFColors.warning)
                }
            }
        }
    }
}

struct YesNoInput: View {
    @Binding var value: String

    var body: some View {
        HStack(spacing: 12) {
            Button {
                value = "yes"
            } label: {
                Text("YES")
                    .font(FFTypography.bodyMediumBold())
                    .foregroundColor(value == "yes" ? .white : FFColors.success.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: FFLayout.minTapTarget)
                    .background(value == "yes" ? FFColors.success : FFColors.surface)
                    .cornerRadius(FFLayout.cornerRadiusSmall)
                    .overlay(
                        RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                            .stroke(FFColors.success.opacity(value == "yes" ? 0 : 0.3), lineWidth: 1)
                    )
            }

            Button {
                value = "no"
            } label: {
                Text("NO")
                    .font(FFTypography.bodyMediumBold())
                    .foregroundColor(value == "no" ? .white : FFColors.danger.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: FFLayout.minTapTarget)
                    .background(value == "no" ? FFColors.danger : FFColors.surface)
                    .cornerRadius(FFLayout.cornerRadiusSmall)
                    .overlay(
                        RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                            .stroke(FFColors.danger.opacity(value == "no" ? 0 : 0.3), lineWidth: 1)
                    )
            }
        }
    }
}

struct DropdownInput: View {
    @Binding var value: String
    let options: [String]
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Text(value.isEmpty ? "Select an option" : value)
                    .foregroundColor(value.isEmpty ? FFColors.textSecondary.opacity(0.4) : FFColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(FFColors.textSecondary)
            }
            .padding()
            .frame(minHeight: FFLayout.minTapTarget)
            .background(FFColors.surface)
            .cornerRadius(FFLayout.cornerRadiusSmall)
            .overlay(
                RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                    .stroke(FFColors.border, lineWidth: 1)
            )
        }
        .fullScreenCover(isPresented: $showPicker) {
            OptionPickerScreen(
                title: "Select Option",
                options: options,
                selectedValue: value,
                onSelect: { selected in
                    value = selected
                    showPicker = false
                },
                onDismiss: { showPicker = false }
            )
        }
    }
}

struct MultiSelectInput: View {
    @Binding var value: String
    let options: [String]
    @State private var showPicker = false

    private var selectedItems: Set<String> {
        Set(value.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) })
    }

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Text(value.isEmpty ? "Select options" : "\(selectedItems.count) selected")
                    .foregroundColor(value.isEmpty ? FFColors.textSecondary.opacity(0.4) : FFColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(FFColors.textSecondary)
            }
            .padding()
            .frame(minHeight: FFLayout.minTapTarget)
            .background(FFColors.surface)
            .cornerRadius(FFLayout.cornerRadiusSmall)
            .overlay(
                RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                    .stroke(FFColors.border, lineWidth: 1)
            )
        }
        .sheet(isPresented: $showPicker) {
            MultiSelectPickerScreen(
                title: "Select Options",
                options: options,
                selectedValues: selectedItems,
                onDone: { selected in
                    value = selected.joined(separator: ", ")
                    showPicker = false
                },
                onDismiss: { showPicker = false }
            )
        }
    }
}

struct DateInput: View {
    @Binding var value: String
    let includeTime: Bool
    @State private var selectedDate = Date()

    var body: some View {
        VStack(alignment: .leading) {
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: includeTime ? [.date, .hourAndMinute] : [.date]
            )
            .datePickerStyle(.compact)
            .tint(FFColors.accentCyan)
            .labelsHidden()
            .onChange(of: selectedDate) { _, newValue in
                let formatter = ISO8601DateFormatter()
                value = formatter.string(from: newValue)
            }

            if !value.isEmpty {
                Button("Clear") {
                    value = ""
                }
                .font(FFTypography.bodySmall())
                .foregroundColor(FFColors.danger)
            }
        }
    }
}

struct PhotoInput: View {
    @Binding var value: String
    let maxPhotos: Int
    @State private var capturedPhotos: [Int] = [] // Placeholder for photo indices

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<maxPhotos, id: \.self) { index in
                    if capturedPhotos.contains(index) {
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(FFColors.accentCyan.opacity(0.2))
                                .frame(height: 100)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 24))
                                        .foregroundColor(FFColors.accentCyan)
                                )

                            Button {
                                capturedPhotos.removeAll { $0 == index }
                                value = "\(capturedPhotos.count) photos"
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(FFColors.danger)
                                    .padding(4)
                            }
                        }
                    } else {
                        Button {
                            capturedPhotos.append(index)
                            value = "\(capturedPhotos.count) photos"
                        } label: {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(FFColors.border, style: StrokeStyle(lineWidth: 1, dash: [6]))
                                .frame(height: 100)
                                .overlay(
                                    VStack(spacing: 4) {
                                        Image(systemName: "camera")
                                            .font(.system(size: 20))
                                        Text("Tap to capture")
                                            .font(FFTypography.bodySmall())
                                    }
                                    .foregroundColor(FFColors.textSecondary)
                                )
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
        }
    }
}

struct SignatureFieldInput: View {
    @Binding var value: String
    var attestationText: String?
    @State private var showSignaturePad = false
    @State private var isSigned = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isSigned {
                // Signed state
                ZStack {
                    RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                        .fill(FFColors.success.opacity(0.1))
                        .frame(height: 120)

                    VStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(FFColors.success)
                        Text("Signed")
                            .font(FFTypography.bodyMediumBold())
                            .foregroundColor(FFColors.success)
                    }
                }
            } else {
                // Unsigned state
                Button {
                    showSignaturePad = true
                } label: {
                    RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                        .stroke(FFColors.border, style: StrokeStyle(lineWidth: 1, dash: [8]))
                        .frame(height: 120)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "signature")
                                    .font(.system(size: 28))
                                Text("Tap to sign")
                                    .font(FFTypography.bodyMedium())
                            }
                            .foregroundColor(FFColors.accentCyan)
                        )
                }
            }

            if let attestation = attestationText {
                Text(attestation)
                    .font(FFTypography.bodySmall())
                    .foregroundColor(FFColors.textSecondary)
                    .italic()
            }
        }
        .fullScreenCover(isPresented: $showSignaturePad) {
            SignatureCaptureView(
                attestationText: attestationText ?? "By signing, I confirm the information above is accurate and complete.",
                onComplete: { _ in
                    isSigned = true
                    value = "signed"
                    showSignaturePad = false
                },
                onCancel: {
                    showSignaturePad = false
                }
            )
        }
    }
}

// MARK: - Option Picker Screen

struct OptionPickerScreen: View {
    let title: String
    let options: [String]
    let selectedValue: String
    let onSelect: (String) -> Void
    let onDismiss: () -> Void
    @State private var searchText = ""

    private var filteredOptions: [String] {
        if searchText.isEmpty { return options }
        return options.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                List {
                    ForEach(filteredOptions, id: \.self) { option in
                        Button {
                            onSelect(option)
                        } label: {
                            HStack {
                                Text(option)
                                    .foregroundColor(FFColors.textPrimary)
                                Spacer()
                                if option == selectedValue {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(FFColors.accentCyan)
                                }
                            }
                        }
                        .listRowBackground(FFColors.surfaceElevated)
                    }
                }
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "Search")
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onDismiss() }
                        .foregroundColor(FFColors.accentCyan)
                }
            }
            .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Multi-Select Picker

struct MultiSelectPickerScreen: View {
    let title: String
    let options: [String]
    let selectedValues: Set<String>
    let onDone: (Set<String>) -> Void
    let onDismiss: () -> Void
    @State private var selected: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                List {
                    ForEach(options, id: \.self) { option in
                        Button {
                            if selected.contains(option) {
                                selected.remove(option)
                            } else {
                                selected.insert(option)
                            }
                        } label: {
                            HStack {
                                Image(systemName: selected.contains(option) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(selected.contains(option) ? FFColors.accentCyan : FFColors.textSecondary)
                                Text(option)
                                    .foregroundColor(FFColors.textPrimary)
                            }
                        }
                        .listRowBackground(FFColors.surfaceElevated)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onDismiss() }
                        .foregroundColor(FFColors.accentCyan)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onDone(selected) }
                        .foregroundColor(FFColors.accentCyan)
                        .fontWeight(.semibold)
                }
            }
            .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear { selected = selectedValues }
    }
}

#Preview {
    NavigationStack {
        FormFillScreen(task: MockData.myTasks[0])
            .environmentObject(AppState())
    }
}

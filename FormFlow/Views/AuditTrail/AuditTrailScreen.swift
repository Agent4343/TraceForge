import SwiftUI

struct AuditTrailScreen: View {
    @EnvironmentObject var appState: AppState
    let workflowId: UUID
    let workflowName: String

    @State private var selectedCategory: AuditCategory = .all
    @State private var showExportMenu = false
    @State private var showCopiedToast = false

    private var entries: [AuditLogEntry] {
        var all = appState.auditEntriesForWorkflow(workflowId)
        if selectedCategory != .all {
            all = all.filter { $0.action.category == selectedCategory }
        }
        return all
    }

    var body: some View {
        ZStack {
            FFColors.primaryNavy.ignoresSafeArea()

            VStack(spacing: 0) {
                // Filter bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(AuditCategory.allCases, id: \.self) { category in
                            FilterChip(title: category.rawValue, isSelected: selectedCategory == category) {
                                withAnimation { selectedCategory = category }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                if entries.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No Events",
                        subtitle: "Audit events will appear here as actions are performed."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(entries) { entry in
                                AuditEntryRow(entry: entry)
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .navigationTitle("Audit Trail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let user = appState.currentUser, user.role.canViewAuditTrail {
                    Menu {
                        Button {
                            exportCSV()
                        } label: {
                            Label("Export as CSV", systemImage: "tablecells")
                        }
                        Button {
                            copyJSON()
                        } label: {
                            Label("Copy raw JSON", systemImage: "doc.on.clipboard")
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
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                Text("Copied to clipboard")
                    .font(FFTypography.bodySmall())
                    .foregroundColor(FFColors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(FFColors.surfaceElevated)
                    .cornerRadius(FFLayout.cornerRadius)
                    .shadow(radius: 4)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Export

    private func exportCSV() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium

        var csv = "Timestamp,Actor,Role,Action,Entity Type,Entity ID,Step,Metadata\n"
        for entry in entries.sorted(by: { $0.timestamp < $1.timestamp }) {
            let step = entry.stepNumber.map { String($0) } ?? ""
            let meta = entry.metadata.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(dateFormatter.string(from: entry.timestamp))\",\"\(entry.actorName)\",\"\(entry.actorRole)\",\"\(entry.action.displayText)\",\"\(entry.entityType)\",\"\(entry.entityId.uuidString)\",\"\(step)\",\"\(meta)\"\n"
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(workflowName)-audit.csv")
        try? csv.write(to: tempURL, atomically: true, encoding: .utf8)

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func copyJSON() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        if let data = try? encoder.encode(entries.sorted(by: { $0.timestamp < $1.timestamp })),
           let json = String(data: data, encoding: .utf8) {
            UIPasteboard.general.string = json
            withAnimation {
                showCopiedToast = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showCopiedToast = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AuditTrailScreen(workflowId: MockData.activeWorkflow.id, workflowName: "Test Workflow")
            .environmentObject(AppState())
    }
}

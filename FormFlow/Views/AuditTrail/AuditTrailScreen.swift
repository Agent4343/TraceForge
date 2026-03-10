import SwiftUI

struct AuditTrailScreen: View {
    @EnvironmentObject var appState: AppState
    let workflowId: UUID
    let workflowName: String

    @State private var selectedCategory: AuditCategory = .all
    @State private var showExportMenu = false

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
                            // Export CSV
                        } label: {
                            Label("Export as CSV", systemImage: "tablecells")
                        }
                        Button {
                            // Copy JSON
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
    }
}

#Preview {
    NavigationStack {
        AuditTrailScreen(workflowId: MockData.activeWorkflow.id, workflowName: "Test Workflow")
            .environmentObject(AppState())
    }
}

import SwiftUI

struct TemplateLibraryScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var statusFilter: TemplateStatus?
    @State private var showCreateTemplate = false

    private var filteredTemplates: [Template] {
        var templates = appState.templates
        if !searchText.isEmpty {
            templates = templates.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if let filter = statusFilter {
            templates = templates.filter { $0.status == filter }
        }
        return templates.sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                FFColors.primaryNavy.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterChip(title: "All", isSelected: statusFilter == nil) {
                                statusFilter = nil
                            }
                            ForEach(TemplateStatus.allCases, id: \.self) { status in
                                FilterChip(title: status.displayName, isSelected: statusFilter == status) {
                                    statusFilter = status
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    if filteredTemplates.isEmpty {
                        EmptyStateView(
                            icon: "doc.on.doc",
                            title: "No Templates",
                            subtitle: "Create a template to define your workflow structure."
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredTemplates) { template in
                                    NavigationLink(destination: TemplateBuilderScreen(template: template)) {
                                        TemplateCard(template: template)
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }
                }

                // FAB
                Button {
                    showCreateTemplate = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(FFColors.primaryNavy)
                        .frame(width: 56, height: 56)
                        .background(FFColors.accentCyan)
                        .clipShape(Circle())
                        .shadow(color: FFColors.accentCyan.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search templates")
            .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showCreateTemplate) {
                TemplateBuilderScreen(template: nil)
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: Template

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(template.name)
                    .font(FFTypography.bodyMediumBold())
                    .foregroundColor(FFColors.textPrimary)
                    .lineLimit(1)

                Spacer()

                StatusBadge.forTemplateStatus(template.status)
            }

            HStack(spacing: 16) {
                Label("\(template.fields.count) fields", systemImage: "list.bullet")
                    .font(FFTypography.bodySmall())
                    .foregroundColor(FFColors.textSecondary)

                Label("\(template.steps.count) steps", systemImage: "arrow.right.arrow.left")
                    .font(FFTypography.bodySmall())
                    .foregroundColor(FFColors.textSecondary)
            }

            HStack {
                Text("Last modified \(relativeDate(template.updatedAt))")
                    .font(FFTypography.bodySmall())
                    .foregroundColor(FFColors.textSecondary)

                Spacer()

                Text("v\(template.version)")
                    .font(FFTypography.mono())
                    .foregroundColor(FFColors.textSecondary)
            }
        }
        .ffCard()
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    TemplateLibraryScreen()
        .environmentObject(AppState())
}

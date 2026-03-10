import SwiftUI

// MARK: - iPad Adaptive Layout

struct AdaptiveLayout<Master: View, Detail: View>: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let master: Master
    let detail: Detail

    init(@ViewBuilder master: () -> Master, @ViewBuilder detail: () -> Detail) {
        self.master = master()
        self.detail = detail()
    }

    var body: some View {
        if sizeClass == .regular {
            // iPad: two-column layout
            HStack(spacing: 0) {
                master
                    .frame(maxWidth: 380)

                Divider()
                    .background(FFColors.border)

                detail
                    .frame(maxWidth: .infinity)
            }
        } else {
            // iPhone: single column with navigation
            master
        }
    }
}

// MARK: - Responsive Grid

struct ResponsiveGrid<Content: View>: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let compactColumns: Int
    let regularColumns: Int
    let spacing: CGFloat
    let content: Content

    init(
        compactColumns: Int = 1,
        regularColumns: Int = 2,
        spacing: CGFloat = FFLayout.spacing,
        @ViewBuilder content: () -> Content
    ) {
        self.compactColumns = compactColumns
        self.regularColumns = regularColumns
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: sizeClass == .regular ? regularColumns : compactColumns
        )

        LazyVGrid(columns: columns, spacing: spacing) {
            content
        }
    }
}

// MARK: - iPad Template Builder

struct iPadTemplateBuilderLayout<StepList: View, FieldList: View>: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let stepList: StepList
    let fieldList: FieldList

    init(@ViewBuilder stepList: () -> StepList, @ViewBuilder fieldList: () -> FieldList) {
        self.stepList = stepList()
        self.fieldList = fieldList()
    }

    var body: some View {
        if sizeClass == .regular {
            HStack(spacing: 0) {
                ScrollView {
                    stepList
                }
                .frame(width: 280)
                .background(FFColors.surface)

                Divider().background(FFColors.border)

                ScrollView {
                    fieldList
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: 0) {
                stepList
                Divider().background(FFColors.border)
                ScrollView {
                    fieldList
                }
            }
        }
    }
}

// MARK: - Sidebar Navigation for iPad

struct iPadSidebarView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: AppTab

    var body: some View {
        List(selection: $selectedTab) {
            Section("Main") {
                Label(AppTab.myTasks.rawValue, systemImage: AppTab.myTasks.icon)
                    .tag(AppTab.myTasks)

                Label(AppTab.workflows.rawValue, systemImage: AppTab.workflows.icon)
                    .tag(AppTab.workflows)

                if let user = appState.currentUser, user.role.canCreateTemplates {
                    Label(AppTab.templates.rawValue, systemImage: AppTab.templates.icon)
                        .tag(AppTab.templates)
                }
            }

            Section("Account") {
                Label(AppTab.profile.rawValue, systemImage: AppTab.profile.icon)
                    .tag(AppTab.profile)
            }
        }
        .listStyle(.sidebar)
        .tint(FFColors.accentCyan)
    }
}

// MARK: - Adaptive Navigation

struct AdaptiveNavigationView<Content: View>: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.horizontalSizeClass) var sizeClass
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if sizeClass == .regular {
            NavigationSplitView {
                iPadSidebarView(selectedTab: $appState.selectedTab)
                    .environmentObject(appState)
            } detail: {
                content
            }
        } else {
            content
        }
    }
}

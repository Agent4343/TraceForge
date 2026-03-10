import SwiftUI

struct PaywallScreen: View {
    @Environment(\.dismiss) var dismiss
    let featureName: String
    let requiredPlan: String

    @State private var showAllPlans = false

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Feature blocked header
                        VStack(spacing: 12) {
                            Image(systemName: "lock.circle")
                                .font(.system(size: 56, weight: .thin))
                                .foregroundColor(FFColors.accentCyan)

                            Text("\(featureName) requires \(requiredPlan) or higher")
                                .font(FFTypography.displaySmall())
                                .foregroundColor(FFColors.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 32)

                        // Benefits
                        VStack(alignment: .leading, spacing: 12) {
                            benefitRow(icon: "doc.richtext", text: "Generate tamper-evident PDF reports")
                            benefitRow(icon: "infinity", text: "Unlimited templates and workflow runs")
                            benefitRow(icon: "person.3", text: "Up to 10 team members")
                            benefitRow(icon: "clock.arrow.circlepath", text: "Full audit trail export")
                        }
                        .ffCard()

                        // Plan comparison
                        VStack(spacing: 12) {
                            planComparisonRow("Current Plan", plan: "Free", highlight: false)
                            planComparisonRow("Recommended", plan: "Pro — $29/month", highlight: true)
                        }

                        // Primary CTA
                        Button {
                            // Would trigger StoreKit purchase
                        } label: {
                            Text("Upgrade to Pro — $29/month")
                                .ffPrimaryButton()
                        }

                        Button {
                            showAllPlans = true
                        } label: {
                            Text("See all plans")
                                .font(FFTypography.bodyMedium())
                                .foregroundColor(FFColors.accentCyan)
                        }
                        .frame(minHeight: FFLayout.minTapTarget)
                    }
                    .padding(24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(FFColors.textSecondary)
                    }
                }
            }
            .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showAllPlans) {
                AllPlansScreen()
            }
        }
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(FFColors.accentCyan)
                .frame(width: 24)
            Text(text)
                .font(FFTypography.bodyMedium())
                .foregroundColor(FFColors.textPrimary)
        }
    }

    private func planComparisonRow(_ label: String, plan: String, highlight: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(FFTypography.bodySmall())
                    .foregroundColor(FFColors.textSecondary)
                Text(plan)
                    .font(FFTypography.bodyMediumBold())
                    .foregroundColor(highlight ? FFColors.accentCyan : FFColors.textPrimary)
            }
            Spacer()
            if highlight {
                Image(systemName: "star.fill")
                    .foregroundColor(FFColors.accentCyan)
            }
        }
        .padding()
        .background(highlight ? FFColors.accentCyan.opacity(0.1) : FFColors.surfaceElevated)
        .cornerRadius(FFLayout.cornerRadiusSmall)
        .overlay(
            RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                .stroke(highlight ? FFColors.accentCyan : FFColors.border, lineWidth: 1)
        )
    }
}

// MARK: - All Plans Screen

struct AllPlansScreen: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        Text("Choose Your Plan")
                            .font(FFTypography.displayMedium())
                            .foregroundColor(FFColors.textPrimary)
                            .padding(.top, 16)

                        // Free
                        planCard(
                            name: "Free",
                            price: "$0",
                            period: "forever",
                            features: [
                                "3 templates",
                                "25 workflow runs/month",
                                "2 users",
                                "Basic support"
                            ],
                            isCurrent: true,
                            accent: FFColors.textSecondary
                        )

                        // Pro
                        planCard(
                            name: "Pro",
                            price: "$29",
                            period: "/month",
                            features: [
                                "Unlimited templates",
                                "Unlimited workflow runs",
                                "Up to 10 users",
                                "PDF export",
                                "Audit trail export",
                                "Priority support"
                            ],
                            isCurrent: false,
                            accent: FFColors.accentCyan
                        )

                        // Pro Annual
                        HStack {
                            Spacer()
                            Text("Save ~20% with annual billing: $279/year")
                                .font(FFTypography.bodySmall())
                                .foregroundColor(FFColors.success)
                            Spacer()
                        }

                        // Business
                        planCard(
                            name: "Business",
                            price: "$59",
                            period: "/user/month",
                            features: [
                                "Everything in Pro",
                                "Unlimited users",
                                "Multi-site support",
                                "Advanced analytics",
                                "Custom branding",
                                "Dedicated support",
                                "SLA guarantee"
                            ],
                            isCurrent: false,
                            accent: FFColors.warning
                        )

                        // Business Annual
                        HStack {
                            Spacer()
                            Text("Save ~20% with annual billing: $566/user/year")
                                .font(FFTypography.bodySmall())
                                .foregroundColor(FFColors.success)
                            Spacer()
                        }
                    }
                    .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(FFColors.accentCyan)
                }
            }
            .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func planCard(name: String, price: String, period: String, features: [String], isCurrent: Bool, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(name)
                    .font(FFTypography.displaySmall())
                    .foregroundColor(accent)

                Spacer()

                if isCurrent {
                    Text("CURRENT")
                        .font(FFTypography.label())
                        .foregroundColor(FFColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(FFColors.border, lineWidth: 1))
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(price)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(FFColors.textPrimary)
                Text(period)
                    .font(FFTypography.bodyMedium())
                    .foregroundColor(FFColors.textSecondary)
            }

            Divider().background(FFColors.border)

            ForEach(features, id: \.self) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(accent)
                    Text(feature)
                        .font(FFTypography.bodyMedium())
                        .foregroundColor(FFColors.textPrimary)
                }
            }

            if !isCurrent {
                Button {
                    // StoreKit purchase
                } label: {
                    Text("Upgrade to \(name)")
                        .font(FFTypography.bodyMediumBold())
                        .foregroundColor(FFColors.primaryNavy)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: FFLayout.minTapTarget)
                        .background(accent)
                        .cornerRadius(FFLayout.cornerRadius)
                }
                .padding(.top, 4)
            }
        }
        .ffCard()
        .overlay(
            RoundedRectangle(cornerRadius: FFLayout.cornerRadius)
                .stroke(accent.opacity(0.5), lineWidth: isCurrent ? 0 : 1)
        )
    }
}

#Preview {
    PaywallScreen(featureName: "PDF Export", requiredPlan: "Pro")
}

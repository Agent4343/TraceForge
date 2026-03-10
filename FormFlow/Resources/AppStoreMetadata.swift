import Foundation

// MARK: - App Store Metadata
// Reference file for App Store Connect submission

enum AppStoreMetadata {

    static let appName = "FormFlow: Workflows & Signatures"
    static let subtitle = "Shift Handover · Audit Trails · Offline"

    static let primaryCategory = "Business"
    static let secondaryCategory = "Productivity"

    static let keywords = """
    checklist, workflow, e-signature, audit trail, inspection, \
    shift handover, compliance, field service, offline forms, safety, \
    permit to work, industrial, operations, digital forms
    """

    static let description = """
    FormFlow turns paper checklists and multi-person processes into tamper-evident \
    digital workflows — built for teams that work in shifts, on-site, or in regulated industries.

    MULTI-STEP WORKFLOWS WITH ROLE-BASED ACCESS
    Create reusable templates and assign each step to the right person. Workers only \
    see and edit their assigned section. Completed steps are locked and cannot be modified.

    LEGALLY-DEFENSIBLE E-SIGNATURES
    Every signature is bound to a verified identity, timestamped, and hashed for tamper \
    evidence. Complete audit trail from first entry to final sign-off.

    BUILT FOR OFFLINE FIRST
    Fill forms and capture signatures without connectivity. Everything syncs automatically \
    when you reconnect — no manual steps required.

    SHIFT HANDOVER BUILT IN
    Transfer in-progress steps to the next shift with mandatory handover notes. The incoming \
    worker sees exactly what was done and what remains.

    TAMPER-EVIDENT PDF REPORTS
    Generate professional reports with all responses, photos, signatures, and a cryptographic \
    hash for integrity verification.

    Used by operations teams in energy, construction, manufacturing, maritime, aviation, \
    healthcare, and more.
    """

    static let promotionalText = """
    Replace paper checklists with tamper-evident digital workflows. Multi-step, multi-person, \
    offline-first — with legally-defensible e-signatures and full audit trails.
    """

    static let whatsNew = """
    FormFlow 1.0 — Initial Release
    • Multi-step workflow templates with role-based access control
    • Legally-defensible e-signatures with SHA-256 hashing
    • Offline-first architecture with automatic sync
    • Shift handover with mandatory notes
    • Tamper-evident PDF export with cryptographic hash
    • Push notifications for assignments, due dates, and handovers
    • Admin panel for user and organization management
    """

    static let privacyPolicyURL = "https://formflow.io/privacy"
    static let termsOfServiceURL = "https://formflow.io/terms"
    static let supportURL = "https://formflow.io/support"
    static let marketingURL = "https://formflow.io"

    // Age rating: 4+
    // No objectionable content

    static let bundleIdentifier = "com.formflow.app"
    static let skuNumber = "FORMFLOW-IOS-001"
    static let buildVersion = "1.0.0"
    static let buildNumber = "1"
}

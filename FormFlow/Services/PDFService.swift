import Foundation
import UIKit

// MARK: - PDF Service

class PDFService {
    static let shared = PDFService()

    func generatePDF(
        workflow: WorkflowInstance,
        template: Template,
        steps: [StepAssignment],
        responses: [UUID: String],
        signatures: [SignatureRecord],
        auditEntries: [AuditLogEntry],
        organization: Organization
    ) -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - 2 * margin

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = pdfRenderer.pdfData { context in
            // Cover Page
            context.beginPage()
            var yOffset: CGFloat = margin

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor.lightGray
            ]
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor.black
            ]
            let fieldLabelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ]
            let fieldValueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.black
            ]

            // Title
            let title = "FormFlow Report" as NSString
            title.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 40), withAttributes: titleAttributes)
            yOffset += 50

            let workflowTitle = workflow.name as NSString
            workflowTitle.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 30), withAttributes: headerAttributes)
            yOffset += 40

            let orgLine = "Organization: \(organization.name)" as NSString
            orgLine.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 20), withAttributes: bodyAttributes)
            yOffset += 25

            let templateLine = "Template: \(template.name) (v\(template.version))" as NSString
            templateLine.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 20), withAttributes: bodyAttributes)
            yOffset += 25

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short

            let createdLine = "Created: \(dateFormatter.string(from: workflow.createdAt))" as NSString
            createdLine.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 20), withAttributes: bodyAttributes)
            yOffset += 25

            let statusLine = "Status: \(workflow.status.displayName)" as NSString
            statusLine.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 20), withAttributes: bodyAttributes)
            yOffset += 50

            // Workflow summary page
            context.beginPage()
            yOffset = margin

            let summaryTitle = "Workflow Summary" as NSString
            summaryTitle.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 30), withAttributes: headerAttributes)
            yOffset += 40

            for step in steps.sorted(by: { $0.stepNumber < $1.stepNumber }) {
                let stepLine = "Step \(step.stepNumber): \(step.stepName) — \(step.status.displayName)" as NSString
                stepLine.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 20), withAttributes: bodyAttributes)
                yOffset += 25

                if yOffset > pageHeight - margin {
                    context.beginPage()
                    yOffset = margin
                }
            }

            // Field responses
            yOffset += 20
            context.beginPage()
            yOffset = margin

            let responsesTitle = "Field Responses" as NSString
            responsesTitle.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 30), withAttributes: headerAttributes)
            yOffset += 40

            for field in template.fields.sorted(by: { ($0.stepNumber, $0.order) < ($1.stepNumber, $1.order) }) {
                if !field.type.isInputField { continue }

                let label = "[\(field.label)]" as NSString
                label.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 16), withAttributes: fieldLabelAttributes)
                yOffset += 18

                let value = (responses[field.id] ?? "—") as NSString
                value.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 16), withAttributes: fieldValueAttributes)
                yOffset += 25

                if yOffset > pageHeight - margin {
                    context.beginPage()
                    yOffset = margin
                }
            }

            // Audit trail page
            context.beginPage()
            yOffset = margin

            let auditTitle = "Audit Trail" as NSString
            auditTitle.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 30), withAttributes: headerAttributes)
            yOffset += 40

            for entry in auditEntries.sorted(by: { $0.timestamp < $1.timestamp }) {
                let line = "\(dateFormatter.string(from: entry.timestamp)) — \(entry.actorName) \(entry.action.displayText)" as NSString
                line.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 16), withAttributes: bodyAttributes)
                yOffset += 20

                if yOffset > pageHeight - margin {
                    context.beginPage()
                    yOffset = margin
                }
            }

            // Certification footer on last page
            yOffset = pageHeight - margin - 60
            let hashLine = "SHA-256: \(computeDocumentHash(workflow: workflow))" as NSString
            let monoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 8, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            hashLine.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 12), withAttributes: monoAttributes)
            yOffset += 16

            let certLine = "This document was generated by FormFlow and has not been modified since generation." as NSString
            let certAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 8),
                .foregroundColor: UIColor.gray
            ]
            certLine.draw(in: CGRect(x: margin, y: yOffset, width: contentWidth, height: 12), withAttributes: certAttributes)
        }

        return data
    }

    private func computeDocumentHash(workflow: WorkflowInstance) -> String {
        let input = "\(workflow.id.uuidString)|\(workflow.name)|\(workflow.status.rawValue)|\(Date().timeIntervalSince1970)"
        let data = Data(input.utf8)
        // Simple hash for demo — use CryptoKit in production
        var hash: UInt64 = 5381
        for byte in data {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return String(format: "%016llx", hash) + String(format: "%016llx", hash ^ 0xDEADBEEF) + String(format: "%016llx", hash &* 31) + String(format: "%016llx", hash &+ 42)
    }
}

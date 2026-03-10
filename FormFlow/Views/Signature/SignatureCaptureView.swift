import SwiftUI

// MARK: - Signature Canvas (UIKit wrapper for smooth 60fps drawing)

struct SignatureCanvasView: UIViewRepresentable {
    @Binding var signatureImage: UIImage?
    @Binding var isEmpty: Bool

    func makeUIView(context: Context) -> SignatureCanvasUIView {
        let view = SignatureCanvasUIView()
        view.delegate = context.coordinator
        view.backgroundColor = UIColor(FFColors.surface)
        return view
    }

    func updateUIView(_ uiView: SignatureCanvasUIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, SignatureCanvasDelegate {
        var parent: SignatureCanvasView

        init(_ parent: SignatureCanvasView) {
            self.parent = parent
        }

        func signatureDidChange(image: UIImage?, hasContent: Bool) {
            parent.signatureImage = image
            parent.isEmpty = !hasContent
        }
    }
}

protocol SignatureCanvasDelegate: AnyObject {
    func signatureDidChange(image: UIImage?, hasContent: Bool)
}

class SignatureCanvasUIView: UIView {
    weak var delegate: SignatureCanvasDelegate?

    private var lines: [[CGPoint]] = []
    private var currentLine: [CGPoint] = []
    private let strokeWidth: CGFloat = 3.0
    private let strokeColor: UIColor = .black

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(strokeWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        for line in lines {
            drawLine(line, in: context)
        }
        drawLine(currentLine, in: context)
    }

    private func drawLine(_ points: [CGPoint], in context: CGContext) {
        guard points.count > 1 else { return }
        context.beginPath()
        context.move(to: points[0])
        for i in 1..<points.count {
            context.addLine(to: points[i])
        }
        context.strokePath()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        currentLine = [point]
        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        currentLine.append(point)
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lines.append(currentLine)
        currentLine = []
        setNeedsDisplay()
        notifyDelegate()
    }

    func clear() {
        lines = []
        currentLine = []
        setNeedsDisplay()
        notifyDelegate()
    }

    func undo() {
        if !lines.isEmpty {
            lines.removeLast()
            setNeedsDisplay()
            notifyDelegate()
        }
    }

    func captureImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { context in
            layer.render(in: context.cgContext)
        }
    }

    private func notifyDelegate() {
        delegate?.signatureDidChange(
            image: captureImage(),
            hasContent: !lines.isEmpty
        )
    }
}

// MARK: - Signature Capture View

struct SignatureCaptureView: View {
    let attestationText: String
    let onComplete: (Data) -> Void
    let onCancel: () -> Void

    @State private var signatureImage: UIImage?
    @State private var isEmpty = true

    var body: some View {
        ZStack {
            FFColors.primaryNavy.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") { onCancel() }
                        .foregroundColor(FFColors.accentCyan)
                        .frame(minHeight: FFLayout.minTapTarget)

                    Spacer()

                    Text("Signature")
                        .font(FFTypography.displaySmall())
                        .foregroundColor(FFColors.textPrimary)

                    Spacer()

                    // Balance spacer
                    Text("Cancel").opacity(0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()

                // Canvas
                VStack(spacing: 12) {
                    SignatureCanvasView(signatureImage: $signatureImage, isEmpty: $isEmpty)
                        .frame(height: 200)
                        .cornerRadius(FFLayout.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: FFLayout.cornerRadius)
                                .stroke(FFColors.border, lineWidth: 1)
                        )
                        .padding(.horizontal, 16)

                    // Signing line
                    HStack {
                        Rectangle()
                            .fill(FFColors.textSecondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)

                    // Attestation
                    Text(attestationText)
                        .font(FFTypography.bodySmall())
                        .foregroundColor(FFColors.textSecondary)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    // Signer info
                    VStack(spacing: 2) {
                        Text("Signed by: Worker")
                            .font(FFTypography.bodySmall())
                            .foregroundColor(FFColors.textSecondary)

                        Text(formattedTimestamp())
                            .font(FFTypography.mono())
                            .foregroundColor(FFColors.textSecondary)
                    }
                }

                Spacer()

                // Action buttons
                VStack(spacing: 8) {
                    Divider().background(FFColors.border)

                    HStack(spacing: 12) {
                        Button("Clear") {
                            isEmpty = true
                            signatureImage = nil
                        }
                        .ffSecondaryButton()

                        Button("Submit & Sign") {
                            if let image = signatureImage, let data = image.pngData() {
                                onComplete(data)
                            }
                        }
                        .ffPrimaryButton(isEnabled: !isEmpty)
                        .disabled(isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    private func formattedTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let local = formatter.string(from: Date())

        let utcFormatter = DateFormatter()
        utcFormatter.dateFormat = "HH:mm"
        utcFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let utc = utcFormatter.string(from: Date())

        return "\(local) (UTC \(utc))"
    }
}

// MARK: - Step Signature Modal

struct StepSignatureModal: View {
    @EnvironmentObject var appState: AppState
    let stepName: String
    let fieldCount: Int
    let workflowId: UUID
    let stepNumber: Int
    let onComplete: () -> Void

    @State private var signatureImage: UIImage?
    @State private var isEmpty = true

    private let defaultAttestation = "I confirm all information entered in this step is accurate, complete, and true to the best of my knowledge."

    var body: some View {
        ZStack {
            FFColors.primaryNavy.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") { onComplete() }
                        .foregroundColor(FFColors.accentCyan)
                        .frame(minHeight: FFLayout.minTapTarget)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        VStack(spacing: 8) {
                            Image(systemName: "signature")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(FFColors.accentCyan)

                            Text("Sign Off — \(stepName)")
                                .font(FFTypography.displaySmall())
                                .foregroundColor(FFColors.textPrimary)

                            Text("You are signing off on \(fieldCount) completed fields in this step")
                                .font(FFTypography.bodyMedium())
                                .foregroundColor(FFColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)

                        // Signature canvas
                        SignatureCanvasView(signatureImage: $signatureImage, isEmpty: $isEmpty)
                            .frame(height: 200)
                            .cornerRadius(FFLayout.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: FFLayout.cornerRadius)
                                    .stroke(FFColors.border, lineWidth: 1)
                            )
                            .padding(.horizontal, 16)

                        // Attestation
                        Text(defaultAttestation)
                            .font(FFTypography.bodySmall())
                            .foregroundColor(FFColors.textSecondary)
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        // Signer identity
                        if let user = appState.currentUser {
                            VStack(spacing: 4) {
                                Text(user.displayName)
                                    .font(FFTypography.bodyMediumBold())
                                    .foregroundColor(FFColors.textPrimary)

                                Text(formattedTimestamp())
                                    .font(FFTypography.mono())
                                    .foregroundColor(FFColors.textSecondary)
                            }
                        }
                    }
                }

                // Submit
                VStack(spacing: 8) {
                    Divider().background(FFColors.border)

                    Button("Submit & Sign") {
                        submitSignature()
                    }
                    .ffPrimaryButton(isEnabled: !isEmpty)
                    .disabled(isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    private func submitSignature() {
        guard let user = appState.currentUser,
              let image = signatureImage,
              let imageData = image.pngData() else {
            print("[FormFlow] Signature submission failed: missing user, image, or image data")
            return
        }

        let record = SignatureService.shared.createSignatureRecord(
            workflowId: workflowId,
            stepNumber: stepNumber,
            signer: user,
            signatureImageData: imageData,
            attestationText: defaultAttestation
        )

        // Verify signature hash was generated
        guard !record.contentHash.isEmpty else {
            print("[FormFlow] Signature hash generation failed")
            return
        }

        // Queue for sync
        SyncService.shared.queueOperation(
            type: .signStep,
            entityType: "signature",
            entityId: record.id
        )

        onComplete()
    }

    private func formattedTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        let local = formatter.string(from: Date())

        let utcFormatter = DateFormatter()
        utcFormatter.dateFormat = "HH:mm 'UTC'"
        utcFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let utc = utcFormatter.string(from: Date())

        return "\(local) · \(utc)"
    }
}

#Preview {
    SignatureCaptureView(
        attestationText: "I confirm this information is accurate.",
        onComplete: { _ in },
        onCancel: {}
    )
}

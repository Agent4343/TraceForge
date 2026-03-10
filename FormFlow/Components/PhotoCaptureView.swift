import SwiftUI
import PhotosUI
import UIKit

// MARK: - Photo Capture Manager

@MainActor
class PhotoCaptureManager: ObservableObject {
    @Published var capturedImages: [CapturedPhoto] = []
    @Published var showCamera = false
    @Published var showPhotoLibrary = false
    @Published var showAnnotation = false
    @Published var selectedPhotoIndex: Int?
    @Published var showFullScreenPreview = false

    let maxPhotos: Int

    init(maxPhotos: Int = 3) {
        self.maxPhotos = maxPhotos
    }

    var canAddMore: Bool {
        capturedImages.count < maxPhotos
    }

    func addImage(_ image: UIImage) {
        guard canAddMore else { return }
        let photo = CapturedPhoto(image: image)
        capturedImages.append(photo)
    }

    func removeImage(at index: Int) {
        guard capturedImages.indices.contains(index) else { return }
        capturedImages.remove(at: index)
    }
}

struct CapturedPhoto: Identifiable {
    let id = UUID()
    var image: UIImage
    var annotation: UIImage?
    var timestamp: Date = Date()

    var compositeImage: UIImage {
        guard let annotation = annotation else { return image }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { ctx in
            image.draw(at: .zero)
            annotation.draw(at: .zero)
        }
    }
}

// MARK: - Camera View (UIKit Wrapper)

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Photo Library Picker

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    let maxSelections: Int
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = maxSelections
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker

        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImages.append(image)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Photo Input with Real Camera

struct EnhancedPhotoInput: View {
    @Binding var value: String
    let maxPhotos: Int
    let requireAnnotation: Bool

    @StateObject private var manager: PhotoCaptureManager
    @State private var cameraImage: UIImage?
    @State private var libraryImages: [UIImage] = []
    @State private var previewPhotoIndex: Int?

    init(value: Binding<String>, maxPhotos: Int = 3, requireAnnotation: Bool = false) {
        self._value = value
        self.maxPhotos = maxPhotos
        self.requireAnnotation = requireAnnotation
        self._manager = StateObject(wrappedValue: PhotoCaptureManager(maxPhotos: maxPhotos))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(manager.capturedImages.enumerated()), id: \.element.id) { index, photo in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: photo.compositeImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(8)
                            .onTapGesture {
                                previewPhotoIndex = index
                            }

                        Button {
                            manager.removeImage(at: index)
                            updateValue()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(FFColors.danger)
                                .background(Circle().fill(.white).padding(2))
                        }
                        .padding(4)
                    }
                    .accessibilityLabel("Photo \(index + 1) of \(manager.capturedImages.count)")
                    .accessibilityHint("Tap to preview, double tap delete button to remove")
                }

                // Add photo slots
                if manager.canAddMore {
                    ForEach(0..<(maxPhotos - manager.capturedImages.count), id: \.self) { _ in
                        Menu {
                            Button {
                                manager.showCamera = true
                            } label: {
                                Label("Take Photo", systemImage: "camera")
                            }

                            Button {
                                manager.showPhotoLibrary = true
                            } label: {
                                Label("Choose from Library", systemImage: "photo.on.rectangle")
                            }
                        } label: {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(FFColors.border, style: StrokeStyle(lineWidth: 1, dash: [6]))
                                .frame(height: 100)
                                .overlay(
                                    VStack(spacing: 4) {
                                        Image(systemName: "camera")
                                            .font(.system(size: 20))
                                        Text("Add Photo")
                                            .font(FFTypography.bodySmall())
                                    }
                                    .foregroundColor(FFColors.textSecondary)
                                )
                        }
                        .accessibilityLabel("Add photo, slot \(manager.capturedImages.count + 1) of \(maxPhotos)")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $manager.showCamera) {
            CameraView(image: $cameraImage)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $manager.showPhotoLibrary) {
            PhotoLibraryPicker(
                selectedImages: $libraryImages,
                maxSelections: maxPhotos - manager.capturedImages.count
            )
        }
        .fullScreenCover(item: Binding(
            get: { previewPhotoIndex.map { PhotoPreviewItem(index: $0) } },
            set: { previewPhotoIndex = $0?.index }
        )) { item in
            PhotoPreviewScreen(
                photo: manager.capturedImages[item.index],
                onAnnotate: { annotatedImage in
                    manager.capturedImages[item.index].annotation = annotatedImage
                    updateValue()
                },
                onDismiss: { previewPhotoIndex = nil }
            )
        }
        .onChange(of: cameraImage) { _, newImage in
            if let img = newImage {
                manager.addImage(img)
                cameraImage = nil
                updateValue()
            }
        }
        .onChange(of: libraryImages) { _, newImages in
            for img in newImages {
                manager.addImage(img)
            }
            libraryImages = []
            updateValue()
        }
    }

    private func updateValue() {
        value = "\(manager.capturedImages.count) photos"
    }
}

struct PhotoPreviewItem: Identifiable {
    let index: Int
    var id: Int { index }
}

// MARK: - Photo Preview with Annotation

struct PhotoPreviewScreen: View {
    let photo: CapturedPhoto
    let onAnnotate: (UIImage) -> Void
    let onDismiss: () -> Void

    @State private var showAnnotation = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                HStack {
                    Button("Close") { onDismiss() }
                        .foregroundColor(.white)
                        .frame(minHeight: FFLayout.minTapTarget)

                    Spacer()

                    Button("Annotate") { showAnnotation = true }
                        .foregroundColor(FFColors.accentCyan)
                        .frame(minHeight: FFLayout.minTapTarget)
                }
                .padding(.horizontal)

                Spacer()

                Image(uiImage: photo.compositeImage)
                    .resizable()
                    .scaledToFit()
                    .padding()

                Spacer()

                Text(formatDate(photo.timestamp))
                    .font(FFTypography.mono())
                    .foregroundColor(.gray)
                    .padding(.bottom)
            }
        }
        .fullScreenCover(isPresented: $showAnnotation) {
            AnnotationView(
                baseImage: photo.image,
                onSave: { annotated in
                    onAnnotate(annotated)
                    showAnnotation = false
                },
                onCancel: { showAnnotation = false }
            )
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.string(from: date)
    }
}

// MARK: - Annotation Drawing View

struct AnnotationView: View {
    let baseImage: UIImage
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var lines: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                HStack {
                    Button("Cancel") { onCancel() }
                        .foregroundColor(.white)
                    Spacer()
                    Button("Clear") { lines = [] }
                        .foregroundColor(FFColors.warning)
                    Spacer()
                    Button("Save") { saveAnnotation() }
                        .foregroundColor(FFColors.accentCyan)
                        .fontWeight(.semibold)
                }
                .padding()

                GeometryReader { geo in
                    ZStack {
                        Image(uiImage: baseImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)

                        Canvas { ctx, _ in
                            for line in lines + [currentLine] {
                                guard line.count > 1 else { continue }
                                var path = Path()
                                path.move(to: line[0])
                                for point in line.dropFirst() {
                                    path.addLine(to: point)
                                }
                                ctx.stroke(path, with: .color(.red), lineWidth: 3)
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    currentLine.append(value.location)
                                }
                                .onEnded { _ in
                                    lines.append(currentLine)
                                    currentLine = []
                                }
                        )
                    }
                }
            }
        }
    }

    private func saveAnnotation() {
        let renderer = UIGraphicsImageRenderer(size: baseImage.size)
        let annotated = renderer.image { ctx in
            // Draw lines on transparent background
            let scaleX = baseImage.size.width / UIScreen.main.bounds.width
            let scaleY = baseImage.size.height / UIScreen.main.bounds.height

            UIColor.red.setStroke()
            for line in lines {
                guard line.count > 1 else { continue }
                let path = UIBezierPath()
                path.lineWidth = 3 * max(scaleX, scaleY)
                path.move(to: CGPoint(x: line[0].x * scaleX, y: line[0].y * scaleY))
                for point in line.dropFirst() {
                    path.addLine(to: CGPoint(x: point.x * scaleX, y: point.y * scaleY))
                }
                path.stroke()
            }
        }
        onSave(annotated)
    }
}

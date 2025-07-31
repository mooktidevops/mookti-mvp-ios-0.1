//
//  MediaThumbnailView.swift
//  Mookti MVP
//
//  Created on 2025-07-21.
//

import SwiftUI
import PDFKit
import QuickLook

struct MediaThumbnailView: View {
    let payload: MediaPayload
    @State private var showingViewer = false
    @State private var selectedFileIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let caption = payload.caption {
                Text(caption)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if payload.files.count == 1 {
                // Single file
                SingleMediaThumbnail(
                    file: payload.files[0],
                    onTap: {
                        selectedFileIndex = 0
                        showingViewer = true
                    }
                )
            } else {
                // Multiple files - show grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(Array(payload.files.enumerated()), id: \.offset) { index, file in
                        SingleMediaThumbnail(
                            file: file,
                            onTap: {
                                selectedFileIndex = index
                                showingViewer = true
                            }
                        )
                        .frame(height: 100)
                    }
                }
            }
        }
        .sheet(isPresented: $showingViewer) {
            MediaViewerSheet(
                files: payload.files,
                selectedIndex: $selectedFileIndex
            )
        }
    }
}

struct SingleMediaThumbnail: View {
    let file: MediaPayload.MediaFile
    let onTap: () -> Void
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
                .overlay {
                    VStack(spacing: 8) {
                        if let thumbnailImage = thumbnailImage {
                            Image(uiImage: thumbnailImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: file.type.systemIconName)
                                .font(.system(size: 24))
                                .foregroundColor(.accentColor)
                        }
                        
                        VStack(spacing: 2) {
                            Text(file.filename)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                            
                            if let caption = file.caption {
                                Text(caption)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(12)
                }
                .frame(height: 120)
        }
        .buttonStyle(.plain)
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard file.type == .image || file.type == .pdf else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            var image: UIImage?
            
            // Extract filename without extension
            let filenameWithoutExtension = file.filename
                .split(separator: ".")
                .dropLast()
                .joined(separator: ".")
            
            // Try multiple paths
            // Start with root since that's where files are actually copied
            let possiblePaths = [
                "",  // Root of bundle (most likely location)
                "Media/\(file.type.folderName)",
                "Resources/Media/\(file.type.folderName)",
                "\(file.type.folderName)"
            ]
            
            var foundURL: URL?
            for path in possiblePaths {
                if let url = Bundle.main.url(
                    forResource: filenameWithoutExtension,
                    withExtension: file.type == .image ? String(file.filename.split(separator: ".").last ?? "jpg") : file.type.rawValue,
                    subdirectory: path.isEmpty ? nil : path
                ) {
                    foundURL = url
                    break
                }
            }
            
            // Also try direct path
            if foundURL == nil {
                foundURL = Bundle.main.url(forResource: file.filename, withExtension: nil)
            }
            
            guard let url = foundURL else {
                print("Thumbnail: Could not find file: \(file.filename)")
                return
            }
            
            if file.type == .image {
                image = UIImage(contentsOfFile: url.path)
            } else if file.type == .pdf,
                      let document = PDFDocument(url: url),
                      let firstPage = document.page(at: 0) {
                let pageRect = firstPage.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200 * pageRect.height / pageRect.width))
                image = renderer.image { context in
                    UIColor.white.set()
                    context.fill(CGRect(origin: .zero, size: renderer.format.bounds.size))
                    
                    context.cgContext.saveGState()
                    context.cgContext.translateBy(x: 0, y: renderer.format.bounds.height)
                    context.cgContext.scaleBy(x: 1.0, y: -1.0)
                    
                    let scaleX = renderer.format.bounds.width / pageRect.width
                    let scaleY = renderer.format.bounds.height / pageRect.height
                    context.cgContext.scaleBy(x: scaleX, y: scaleY)
                    
                    firstPage.draw(with: .mediaBox, to: context.cgContext)
                    context.cgContext.restoreGState()
                }
            }
            
            DispatchQueue.main.async {
                self.thumbnailImage = image
            }
        }
    }
}

struct MediaViewerSheet: View {
    let files: [MediaPayload.MediaFile]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedIndex) {
                ForEach(Array(files.enumerated()), id: \.offset) { index, file in
                    MediaFileViewer(file: file)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: files.count > 1 ? .always : .never))
            .navigationTitle(files[selectedIndex].filename)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MediaFileViewer: View {
    let file: MediaPayload.MediaFile
    @State private var pdfDocument: PDFDocument?
    @State private var image: UIImage?
    
    var body: some View {
        ScrollView {
            VStack {
                switch file.type {
                case .image:
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        ProgressView("Loading image...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                case .pdf:
                    if let pdfDocument = pdfDocument {
                        PDFViewRepresentable(document: pdfDocument)
                            .frame(minHeight: 600)
                    } else {
                        ProgressView("Loading PDF...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                case .video:
                    VStack {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        Text("Video playback coming soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                if let caption = file.caption {
                    Text(caption)
                        .font(.body)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding()
                }
            }
        }
        .onAppear {
            loadContent()
        }
    }
    
    private func loadContent() {
        // Extract filename without extension
        let filenameWithoutExtension = file.filename
            .split(separator: ".")
            .dropLast()
            .joined(separator: ".")
        
        // Try multiple paths for backward compatibility
        // Start with root since that's where files are actually copied
        let possiblePaths = [
            "",  // Root of bundle (most likely location)
            "Media/\(file.type.folderName)",
            "Resources/Media/\(file.type.folderName)",
            "\(file.type.folderName)"
        ]
        
        var foundURL: URL?
        for path in possiblePaths {
            if let url = Bundle.main.url(
                forResource: filenameWithoutExtension,
                withExtension: file.type == .image ? String(file.filename.split(separator: ".").last ?? "jpg") : file.type.rawValue,
                subdirectory: path.isEmpty ? nil : path
            ) {
                foundURL = url
                print("Found file at: \(url.path)")
                break
            }
        }
        
        if foundURL == nil {
            // Also try direct path
            foundURL = Bundle.main.url(forResource: file.filename, withExtension: nil)
            if let url = foundURL {
                print("Found with direct search at: \(url.path)")
            }
        }
        
        guard let url = foundURL else {
            print("Could not find file: \(file.filename)")
            print("Searched in: \(possiblePaths)")
            return
        }
        
        switch file.type {
        case .image:
            image = UIImage(contentsOfFile: url.path)
        case .pdf:
            pdfDocument = PDFDocument(url: url)
            if pdfDocument == nil {
                print("Failed to create PDFDocument from URL: \(url)")
            }
        case .video:
            // Video handling would go here
            break
        }
    }
}

struct PDFViewRepresentable: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}

#Preview {
    let samplePayload = MediaPayload(
        files: [
            MediaPayload.MediaFile(filename: "sample.pdf", type: .pdf, caption: "Sample PDF document"),
            MediaPayload.MediaFile(filename: "image.jpg", type: .image, caption: "Sample image")
        ],
        caption: "Sample media files"
    )
    
    MediaThumbnailView(payload: samplePayload)
        .padding()
}
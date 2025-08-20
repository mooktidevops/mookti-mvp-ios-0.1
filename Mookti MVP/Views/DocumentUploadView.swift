import SwiftUI
import UniformTypeIdentifiers

struct DocumentUploadView: View {
    @StateObject private var uploadManager = DocumentUploadManager()
    @State private var showingFilePicker = false
    @State private var showingCamera = false
    @State private var uploadProgress: Double = 0
    @State private var selectedDocument: UploadedDocument? = nil
    @State private var showDeleteConfirmation = false
    @State private var documentToDelete: UploadedDocument? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with quota
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("My Documents", systemImage: "folder")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Upload button
                    Menu {
                        Button(action: { showingFilePicker = true }) {
                            Label("Choose File", systemImage: "doc")
                        }
                        
                        Button(action: { showingCamera = true }) {
                            Label("Scan Document", systemImage: "camera")
                        }
                    } label: {
                        Label("Upload", systemImage: "plus.circle.fill")
                            .font(.caption)
                    }
                    .disabled(!uploadManager.canUpload)
                }
                
                // Storage quota
                QuotaIndicator(
                    used: uploadManager.storageUsedMB,
                    limit: uploadManager.storageLimitMB,
                    uploadsToday: uploadManager.uploadsToday,
                    dailyLimit: uploadManager.dailyUploadLimit
                )
            }
            
            // Upload progress
            if uploadManager.isUploading {
                UploadProgressView(
                    fileName: uploadManager.currentUploadName ?? "File",
                    progress: uploadManager.uploadProgress
                )
            }
            
            // Documents list
            if uploadManager.documents.isEmpty {
                EmptyDocumentsView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(uploadManager.documents) { document in
                            DocumentRow(
                                document: document,
                                isSelected: selectedDocument?.id == document.id,
                                onTap: {
                                    selectedDocument = document
                                },
                                onDelete: {
                                    documentToDelete = document
                                    showDeleteConfirmation = true
                                }
                            )
                        }
                    }
                }
            }
            
            // Selected document details
            if let selected = selectedDocument {
                DocumentDetailsView(document: selected)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: allowedTypes,
            onCompletion: handleFileSelection
        )
        .alert("Delete Document", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let doc = documentToDelete {
                    uploadManager.deleteDocument(doc)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(documentToDelete?.fileName ?? "")'? This action cannot be undone.")
        }
        .onAppear {
            uploadManager.loadDocuments()
        }
    }
    
    private var allowedTypes: [UTType] {
        [.pdf, .text, .plainText, .rtf, .html, .markdown]
    }
    
    private func handleFileSelection(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            uploadManager.uploadDocument(from: url)
        case .failure(let error):
            print("File selection error: \(error)")
        }
    }
}

struct QuotaIndicator: View {
    let used: Double
    let limit: Double
    let uploadsToday: Int
    let dailyLimit: Int
    
    private var usagePercent: Double {
        guard limit > 0 else { return 0 }
        return min(1, used / limit)
    }
    
    private var storageColor: Color {
        if usagePercent > 0.9 { return .red }
        if usagePercent > 0.7 { return .orange }
        return .green
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Storage bar
            HStack(spacing: 8) {
                Image(systemName: "internaldrive")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(storageColor)
                            .frame(width: geometry.size.width * usagePercent)
                    }
                }
                .frame(height: 8)
                
                Text("\(Int(used))MB / \(Int(limit))MB")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Upload limit
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.circle")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(uploadsToday) of \(dailyLimit) uploads today")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if uploadsToday >= dailyLimit {
                    Text("(Limit reached)")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct UploadProgressView: View {
    let fileName: String
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "arrow.up.doc")
                    .foregroundColor(.blue)
                Text("Uploading: \(fileName)")
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
}

struct EmptyDocumentsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No documents uploaded yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Upload PDFs, text files, or other documents to enhance Ellen's ability to help you learn.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DocumentRow: View {
    let document: UploadedDocument
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // File type icon
                Image(systemName: document.fileIcon)
                    .font(.title3)
                    .foregroundColor(document.fileColor)
                    .frame(width: 40, height: 40)
                    .background(document.fileColor.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.fileName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(document.formattedSize)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(document.uploadDate, formatter: dateFormatter)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if document.chunks > 0 {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("\(document.chunks) chunks")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.05) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

struct DocumentDetailsView: View {
    let document: UploadedDocument
    @State private var showingPreview = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Document Details", systemImage: "info.circle")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingPreview = true }) {
                    Label("Preview", systemImage: "eye")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "ID", value: document.id)
                DetailRow(label: "Type", value: document.fileType)
                DetailRow(label: "Indexed", value: document.isIndexed ? "Yes" : "Processing...")
                
                if document.isIndexed {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Available for search")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.02))
        .cornerRadius(8)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .lineLimit(1)
        }
    }
}

// Document Upload Manager
class DocumentUploadManager: ObservableObject {
    @Published var documents: [UploadedDocument] = []
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var currentUploadName: String? = nil
    
    // Quota properties (would come from entitlements)
    @Published var storageUsedMB: Double = 234
    @Published var storageLimitMB: Double = 1024
    @Published var uploadsToday: Int = 2
    @Published var dailyUploadLimit: Int = 5
    
    var canUpload: Bool {
        uploadsToday < dailyUploadLimit && storageUsedMB < storageLimitMB
    }
    
    func loadDocuments() {
        // Load from API/storage
        documents = [
            UploadedDocument(
                id: "doc_123",
                fileName: "Linear Algebra Notes.pdf",
                fileType: "application/pdf",
                fileSize: 2048576,
                uploadDate: Date().addingTimeInterval(-86400),
                chunks: 42,
                isIndexed: true
            ),
            UploadedDocument(
                id: "doc_124",
                fileName: "Physics Problem Set.txt",
                fileType: "text/plain",
                fileSize: 524288,
                uploadDate: Date().addingTimeInterval(-172800),
                chunks: 12,
                isIndexed: true
            )
        ]
    }
    
    func uploadDocument(from url: URL) {
        guard canUpload else { return }
        
        isUploading = true
        currentUploadName = url.lastPathComponent
        
        // Simulate upload progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            self.uploadProgress += 0.1
            
            if self.uploadProgress >= 1.0 {
                timer.invalidate()
                self.completeUpload(fileName: url.lastPathComponent)
            }
        }
    }
    
    private func completeUpload(fileName: String) {
        let newDoc = UploadedDocument(
            id: "doc_\(UUID().uuidString.prefix(8))",
            fileName: fileName,
            fileType: "application/pdf",
            fileSize: Int.random(in: 100000...5000000),
            uploadDate: Date(),
            chunks: Int.random(in: 5...50),
            isIndexed: false
        )
        
        documents.insert(newDoc, at: 0)
        uploadsToday += 1
        storageUsedMB += Double(newDoc.fileSize) / (1024 * 1024)
        
        isUploading = false
        uploadProgress = 0
        currentUploadName = nil
        
        // Simulate indexing completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if let index = self.documents.firstIndex(where: { $0.id == newDoc.id }) {
                self.documents[index].isIndexed = true
            }
        }
    }
    
    func deleteDocument(_ document: UploadedDocument) {
        documents.removeAll { $0.id == document.id }
        storageUsedMB -= Double(document.fileSize) / (1024 * 1024)
    }
}

// Data Model
struct UploadedDocument: Identifiable {
    let id: String
    let fileName: String
    let fileType: String
    let fileSize: Int
    let uploadDate: Date
    let chunks: Int
    var isIndexed: Bool
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }
    
    var fileIcon: String {
        if fileType.contains("pdf") { return "doc.text" }
        if fileType.contains("text") { return "doc.plaintext" }
        if fileType.contains("image") { return "photo" }
        return "doc"
    }
    
    var fileColor: Color {
        if fileType.contains("pdf") { return .red }
        if fileType.contains("text") { return .blue }
        if fileType.contains("image") { return .green }
        return .gray
    }
}
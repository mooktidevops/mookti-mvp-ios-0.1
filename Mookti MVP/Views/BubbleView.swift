//
//  BubbleView.swift
//  Mookti
//

import SwiftUI

struct BubbleView: View {
    var message: Message
    @State private var showingDisclaimer = false

    private var isUser: Bool { message.role == .user }
    
    /// Check if content contains interactive annotations
    private func containsInteractiveAnnotations(_ content: String) -> Bool {
        content.contains("${ON HOVER:") || 
        content.contains("[ON HOVER:") ||
        content.contains("${on hover:") ||
        content.contains("[on hover:")
    }
    
    /// Check if this is a media message
    private func isMediaMessage() -> Bool {
        // Check if content starts with media JSON or has media file extension
        return message.content.hasPrefix("{\"files\":") ||
               message.content.hasPrefix("{\"type\": \"media\"") ||
               hasMediaFileExtension(message.content)
    }
    
    /// Check if content has a media file extension
    private func hasMediaFileExtension(_ content: String) -> Bool {
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return cleanContent.hasSuffix(".pdf") ||
               cleanContent.hasSuffix(".jpg") ||
               cleanContent.hasSuffix(".jpeg") ||
               cleanContent.hasSuffix(".png") ||
               cleanContent.hasSuffix(".gif") ||
               cleanContent.hasSuffix(".mp4") ||
               cleanContent.hasSuffix(".mov")
    }
    
    /// Check if message should show AI info icon
    private var shouldShowAIInfo: Bool {
        // Don't show AI info for error messages
        let isErrorMessage = message.content.contains("⚠️") || 
                            message.content.lowercased().contains("error:") ||
                            message.content.contains("unavailable") ||
                            message.content.contains("failed")
        
        // Show AI info only for successfully generated/retrieved content
        return (message.source == .aiGenerated || message.source == .aiRetrieved) && !isErrorMessage
    }

    var body: some View {
        HStack {
            if isUser { Spacer() }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 4) {
                    // Message bubble
                    if message.content.hasPrefix("### Chunk") {
                        DisclosureGroup("Sources") {
                            Text(message.content)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        .padding(12)
                        .background(isUser ? Color.accentColor.opacity(0.15)
                                           : Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .foregroundColor(isUser ? .primary : .primary)
                        .frame(maxWidth: 260, alignment: isUser ? .trailing : .leading)
                    } else if isMediaMessage() {
                        // Media content
                        if let mediaPayload = createMediaPayload() {
                            MediaThumbnailView(payload: mediaPayload)
                                .padding(12)
                                .background(isUser ? Color.accentColor.opacity(0.15)
                                                   : Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
                        } else {
                            Text("Media file not found: \(message.content)")
                                .foregroundColor(.red)
                                .padding(12)
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .frame(maxWidth: 260, alignment: isUser ? .trailing : .leading)
                        }
                    } else if let carousel = message.carouselPayload {
                        // Card carousel content
                        CardCarouselView(payload: carousel)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        // Check if content has interactive annotations
                        if containsInteractiveAnnotations(message.content) {
                            InteractiveTextView(content: message.content)
                                .padding(12)
                                .background(isUser ? Color.accentColor.opacity(0.15)
                                                   : Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .foregroundColor(isUser ? .primary : .primary)
                                .frame(maxWidth: 260, alignment: isUser ? .trailing : .leading)
                        } else {
                            Text(message.content)
                                .padding(12)
                                .background(isUser ? Color.accentColor.opacity(0.15)
                                                   : Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .foregroundColor(isUser ? .primary : .primary)
                                .frame(maxWidth: 260, alignment: isUser ? .trailing : .leading)
                        }
                    }
                    
                    // AI info icon
                    if shouldShowAIInfo && !isUser {
                        Button(action: { showingDisclaimer.toggle() }) {
                            Image(systemName: "info.circle")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !isUser { Spacer() }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .alert("AI Information", isPresented: $showingDisclaimer) {
            Button("OK") { }
        } message: {
            Text(disclaimerText)
        }
    }
    
    private var disclaimerText: String {
        switch message.source {
        case .aiGenerated:
            return "This response was generated by AI and may contain inaccuracies. Please verify important information."
        case .aiRetrieved:
            return "This content was written and validated by human experts. AI assisted in retrieving the most relevant information for your query."
        case .csv:
            return "" // Should not show for CSV content
        }
    }
    
    /// Create MediaPayload from message content
    private func createMediaPayload() -> MediaPayload? {
        // Handle JSON format
        if message.content.hasPrefix("{") {
            let fixedJSON = message.content
                .replacingOccurrences(of: #"(\w+):"#, with: "\"$1\":", options: .regularExpression)
                .replacingOccurrences(of: "'", with: "\"")
            
            do {
                return try JSONDecoder().decode(MediaPayload.self, from: Data(fixedJSON.utf8))
            } catch {
                print("Failed to decode MediaPayload from message: \(error)")
                return nil
            }
        }
        
        // Handle simple filename format
        let filename = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let fileExtension = String(filename.split(separator: ".").last ?? "").lowercased()
        
        let mediaType: MediaPayload.MediaFile.MediaType
        switch fileExtension {
        case "pdf":
            mediaType = .pdf
        case "jpg", "jpeg", "png", "gif", "heic":
            mediaType = .image
        case "mp4", "mov", "avi":
            mediaType = .video
        default:
            return nil
        }
        
        let mediaFile = MediaPayload.MediaFile(
            filename: filename,
            type: mediaType,
            caption: nil
        )
        
        return MediaPayload(files: [mediaFile], caption: nil)
    }
}

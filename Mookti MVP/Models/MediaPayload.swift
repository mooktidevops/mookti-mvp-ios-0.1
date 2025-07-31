//
//  MediaPayload.swift
//  Mookti MVP
//
//  Created on 2025-07-21.
//

import Foundation

struct MediaPayload: Codable {
    let files: [MediaFile]
    let caption: String?
    
    struct MediaFile: Codable, Identifiable {
        let filename: String
        let type: MediaType
        let caption: String?
        
        var id: String {
            // Use filename as the stable identifier
            filename
        }
        
        enum MediaType: String, Codable, CaseIterable {
            case pdf = "pdf"
            case image = "image"
            case video = "video"
            
            var folderName: String {
                switch self {
                case .pdf: return "PDFs"
                case .image: return "Images"
                case .video: return "Videos"
                }
            }
            
            var systemIconName: String {
                switch self {
                case .pdf: return "doc.fill"
                case .image: return "photo.fill"
                case .video: return "play.rectangle.fill"
                }
            }
        }
        
        /// Full path to the media file in the app bundle
        var bundlePath: String {
            "Media/\(type.folderName)/\(filename)"
        }
        
        /// Check if file exists in bundle
        var existsInBundle: Bool {
            Bundle.main.url(forResource: filename.replacingOccurrences(of: ".\(type.rawValue)", with: ""), 
                           withExtension: type.rawValue, 
                           subdirectory: "Media/\(type.folderName)") != nil
        }
    }
}

extension LearningNode {
    /// Attempt to decode content as MediaPayload
    func asMediaPayload() -> MediaPayload? {
        guard type == .media else { return nil }
        
        // Handle both JSON format and simple filename format
        if content.hasPrefix("{") {
            // JSON format: {"files": [{"filename": "doc.pdf", "type": "pdf", "caption": "..."}]}
            let fixedJSON = content
                .replacingOccurrences(of: #"(\w+):"#, with: "\"$1\":", options: .regularExpression)
                .replacingOccurrences(of: "'", with: "\"")
            
            do {
                return try JSONDecoder().decode(MediaPayload.self, from: Data(fixedJSON.utf8))
            } catch {
                print("Failed to decode MediaPayload: \(error)")
                return nil
            }
        } else {
            // Simple format: just a filename, infer type from extension
            let filename = content.trimmingCharacters(in: .whitespacesAndNewlines)
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
}
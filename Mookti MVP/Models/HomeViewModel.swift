//
//  HomeViewModel.swift
//  Mookti
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {

    // Published for the view
    @Published private(set) var progress: [String: Double] = [:]

    /// Overall completion (0…1)
    var overall: Double {
        let vals = progress.values
        return vals.isEmpty ? 0 : vals.reduce(0, +) / Double(vals.count)
    }

    // Private
    private var cancellable: AnyCancellable?

    // Inject UserProgressService and start listening
    init(progressService: UserProgressService) {
        cancellable = progressService.$progress
            .sink { [weak self] in self?.progress = $0 }
    }

    /// Manual refresh (not strictly necessary, but handy for pull‑to‑refresh later)
    func refresh(progressService: UserProgressService) {
        progress = progressService.progress
    }
}

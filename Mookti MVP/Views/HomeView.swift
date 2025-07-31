//
//  HomeView.swift
//  Mookti
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var progressService: UserProgressService
    // @EnvironmentObject private var modelAvailability: ModelAvailabilityManager // DEPRECATED: Using cloud-only AI

    @StateObject private var vm: HomeViewModel
    = HomeViewModel(progressService: UserProgressService())
    
    @StateObject private var auth = AuthService.shared

    // NEW: get push closure from parent
    var onContinue: () -> Void = {}

    // Menu toggle is passed down from RootNavigationView if needed
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {

                // Greeting
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back")
                            .font(.title2).bold()
                        Text("Ellen is ready to help you learn.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Ring grid
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 28) {
                    ForEach(vm.progress.sorted(by: { $0.key < $1.key }), id: \.key) { topic, value in
                        ProgressRing(percent: value, label: topic)
                    }
                    ProgressRing(percent: vm.overall, label: "Overall")
                }

                // Continue button - UPDATED to use closure instead of NavigationLink
                Button("Continue Learning") {
                    onContinue()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                
                // Admin controls
                if !auth.isAdminMode {
                    Button("Admin Login") {
                        auth.adminLogin()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Home")
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
                .environmentObject(UserProgressService())
                // .environmentObject(ModelAvailabilityManager()) // DEPRECATED: Using cloud-only AI
        }
    }
}
#endif

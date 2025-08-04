//
//  HomeView.swift
//  Mookti
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var progressService: UserProgressService
    @EnvironmentObject private var conversationStore: ConversationStore
    
    @StateObject private var vm: HomeViewModel = HomeViewModel(progressService: UserProgressService())
    @StateObject private var auth = AuthService.shared
    
    @State private var showStudyGuideAlert = false

    // Navigation callbacks
    var onContinue: () -> Void = {}
    var onEllen: () -> Void = {}
    var onTeams: () -> Void = {}
    var onHistory: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Profile Greeting Section
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hi, Jamie!")
                                .font(.custom("Nunito-Bold", size: 32))
                                .foregroundColor(Color.theme.textPrimary)
                        }
                        
                        Spacer()
                        
                        // Profile Picture
                        ZStack {
                            Circle()
                                .fill(Color.theme.softPink)
                                .frame(width: 60, height: 60)
                            
                            Text("JD")
                                .font(.custom("Nunito-SemiBold", size: 20))
                                .foregroundColor(Color.theme.accent)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Progress Pills
                    VStack(alignment: .leading, spacing: 12) {
                        Text("workplace success learning path")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(Color.theme.textPrimary.opacity(0.7))
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<5) { index in
                                    Capsule()
                                        .fill(index < 3 ? Color.theme.accent : Color.theme.softPink.opacity(0.5))
                                        .frame(width: index == 2 ? 60 : index < 3 ? 80 : 40, height: 8)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    // Current Focus Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Current Focus:")
                            .font(.custom("Nunito-SemiBold", size: 20))
                            .foregroundColor(Color.theme.textPrimary)
                            .italic()
                        
                        Text("Intro to Cultural Intelligence")
                            .font(.custom("Nunito-Bold", size: 28))
                            .foregroundColor(Color.theme.textPrimary)
                            .padding(.bottom, 8)
                        
                        Button(action: onContinue) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(LinearGradient(
                                        colors: [Color.theme.accent, Color.theme.accent.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(height: 160)
                                
                                VStack {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.white.opacity(0.9))
                                    Text("Continue Learning")
                                        .font(.custom("Inter-Medium", size: 16))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .shadow(color: Color.theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                    
                    // Study Guides Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Study Guides")
                            .font(.custom("Nunito-Bold", size: 24))
                            .foregroundColor(Color.theme.textPrimary)
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(0..<4) { _ in
                                    Button(action: { showStudyGuideAlert = true }) {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.theme.accent.opacity(0.8))
                                            .frame(width: 120, height: 120)
                                            .overlay(
                                                Image(systemName: "doc.text.fill")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(.white.opacity(0.8))
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    // Conversation History Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Conversation History")
                            .font(.custom("Nunito-Bold", size: 24))
                            .foregroundColor(Color.theme.textPrimary)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 0) {
                            ForEach([
                                "Conversations on Human Difference",
                                "Understanding Cultural Intelligence",
                                "Bias, Belonging, and Cultural Awareness",
                                "Cultural Code-Switching 101",
                                "Walking in Their Shoes: Empathy and CQ",
                                "Leadership Across Borders"
                            ], id: \.self) { title in
                                Button(action: onHistory) {
                                    HStack {
                                        Text(title)
                                            .font(.custom("Inter-Regular", size: 15))
                                            .foregroundColor(Color.theme.textPrimary)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.theme.textPrimary.opacity(0.5))
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                                    .background(Color.theme.background)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if title != "Leadership Across Borders" {
                                    Divider()
                                        .background(Color.theme.textPrimary.opacity(0.1))
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                        .background(Color.theme.softPink.opacity(0.3))
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 20)
                }
            }
            
            BottomBar(onEllen: onEllen, onHome: {}, onTeams: onTeams)
        }
        .background(Color.theme.background)
        .navigationTitle("")
        .navigationBarHidden(true)
        .limitedPreviewAlert(isPresented: $showStudyGuideAlert, feature: "Study guides")
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
                .environmentObject(UserProgressService())
                .environmentObject(ConversationStore())
        }
    }
}
#endif
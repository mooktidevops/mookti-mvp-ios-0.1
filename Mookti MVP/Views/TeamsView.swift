import SwiftUI

struct TeamsView: View {
    @State private var showAlert = false
    @State private var alertFeature = ""
    @State private var checkedGoals: Set<Int> = [0, 4]
    
    var onHome: () -> Void = {}
    var onEllen: () -> Void = {}
    
    let weeklyGoals = [
        "Complete assigned reading",
        "Review feedback from instructor",
        "Plan next week's agenda & task assignments",
        "Create 1 collaborative deliverable",
        "Define this week's learning goal"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Team")
                            .font(.custom("Inter-Regular", size: 16))
                            .foregroundColor(Color.theme.textPrimary.opacity(0.6))
                        
                        Text("Workplace Success")
                            .font(.custom("Lora-Regular", size: 34))
                            .foregroundColor(Color.theme.textPrimary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    Button(action: {
                        alertFeature = "Team video"
                        showAlert = true
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "E5E5E5"))
                                .frame(height: 200)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 3)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gray.opacity(0.6))
                                )
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Weekly Goals")
                            .font(.custom("Lora-Regular", size: 28))
                            .foregroundColor(Color.theme.textPrimary)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(0..<weeklyGoals.count, id: \.self) { index in
                                HStack(alignment: .top, spacing: 16) {
                                    Button(action: {
                                        if checkedGoals.contains(index) {
                                            checkedGoals.remove(index)
                                        } else {
                                            checkedGoals.insert(index)
                                        }
                                    }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.theme.textPrimary, lineWidth: 2)
                                                .frame(width: 24, height: 24)
                                            
                                            if checkedGoals.contains(index) {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(Color.theme.accent)
                                            }
                                        }
                                    }
                                    
                                    Text(weeklyGoals[index])
                                        .font(.custom("Inter-Regular", size: 18))
                                        .foregroundColor(Color.theme.textPrimary)
                                        .strikethrough(index == 1 || index == 4, color: Color.theme.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 12)
                                
                                if index < weeklyGoals.count - 1 {
                                    Divider()
                                        .background(Color.gray.opacity(0.2))
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.theme.textPrimary, lineWidth: 2)
                        )
                        .padding(.horizontal, 24)
                        
                        Button(action: {
                            alertFeature = "Goal personalization"
                            showAlert = true
                        }) {
                            Text("Personalize Goals")
                                .font(.custom("Inter-Regular", size: 16))
                                .foregroundColor(Color.theme.textPrimary.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.horizontal, 24)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Team Chat")
                            .font(.custom("Lora-Regular", size: 28))
                            .foregroundColor(Color.theme.textPrimary)
                            .padding(.horizontal, 24)
                        
                        Button(action: {
                            alertFeature = "Team chat"
                            showAlert = true
                        }) {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.theme.accent)
                                .frame(height: 60)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            
            BottomBar(onEllen: onEllen, onHome: onHome, onTeams: {})
        }
        .background(Color.theme.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .limitedPreviewAlert(isPresented: $showAlert, feature: alertFeature)
    }
}
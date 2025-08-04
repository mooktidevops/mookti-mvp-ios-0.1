import SwiftUI

struct TeamMember: Identifiable {
    let id = UUID()
    let name: String
    let profileImage: String?
    let initials: String
    let role: String?
}

struct TeamsView: View {
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let teamMembers = [
        TeamMember(name: "Abdikadir A.", profileImage: nil, initials: "AA", role: "Team Lead"),
        TeamMember(name: "Hassan A.", profileImage: nil, initials: "HA", role: "Developer"),
        TeamMember(name: "Maria K.", profileImage: nil, initials: "MK", role: "Designer"),
        TeamMember(name: "Samara P.", profileImage: nil, initials: "SP", role: "Analyst"),
        TeamMember(name: "Alexis S.", profileImage: nil, initials: "AS", role: "Manager"),
        TeamMember(name: "Emily G.", profileImage: nil, initials: "EG", role: "Developer"),
        TeamMember(name: "Jayda R.", profileImage: nil, initials: "JR", role: "Designer"),
        TeamMember(name: "Michael T.", profileImage: nil, initials: "MT", role: "Analyst")
    ]
    
    var onHome: () -> Void = {}
    var onEllen: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Team")
                    .font(.custom("Nunito-Bold", size: 32))
                    .foregroundColor(Color.theme.textPrimary)
                
                Text("Collaborate and learn together")
                    .font(.custom("Inter-Regular", size: 16))
                    .foregroundColor(Color.theme.textPrimary.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 24) {
                    ForEach(teamMembers) { member in
                        Button(action: { 
                            alertMessage = "Team member profiles"
                            showAlert = true
                        }) {
                            VStack(spacing: 8) {
                                // Profile circle
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [Color.theme.softPink, Color.theme.accent.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 85, height: 85)
                                        .shadow(color: Color.theme.accent.opacity(0.2), radius: 8, x: 0, y: 4)
                                    
                                    if let image = member.profileImage {
                                        Image(image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(Circle())
                                    } else {
                                        Text(member.initials)
                                            .font(.custom("Nunito-Bold", size: 26))
                                            .foregroundColor(Color.theme.accent)
                                    }
                                }
                                
                                VStack(spacing: 2) {
                                    Text(member.name)
                                        .font(.custom("Inter-Medium", size: 14))
                                        .foregroundColor(Color.theme.textPrimary)
                                        .lineLimit(1)
                                    
                                    if let role = member.role {
                                        Text(role)
                                            .font(.custom("Inter-Regular", size: 11))
                                            .foregroundColor(Color.theme.textPrimary.opacity(0.6))
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    // Add team member button
                    Button(action: { 
                        alertMessage = "Adding team members"
                        showAlert = true
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                    .foregroundColor(Color.theme.accent.opacity(0.5))
                                    .frame(width: 85, height: 85)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(Color.theme.accent)
                            }
                            
                            VStack(spacing: 2) {
                                Text("Add Member")
                                    .font(.custom("Inter-Medium", size: 14))
                                    .foregroundColor(Color.theme.accent)
                                
                                Text("Invite")
                                    .font(.custom("Inter-Regular", size: 11))
                                    .foregroundColor(Color.theme.accent.opacity(0.6))
                            }
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
            
            BottomBar(onEllen: onEllen, onHome: onHome, onTeams: {})
        }
        .background(Color.theme.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .limitedPreviewAlert(isPresented: $showAlert, feature: alertMessage)
    }
}

// Custom button style for scaling animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
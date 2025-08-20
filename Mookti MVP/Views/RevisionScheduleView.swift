import SwiftUI

struct RevisionScheduleView: View {
    let schedule: RevisionSchedule
    @State private var selectedDate: Date = Date()
    @State private var viewMode: ViewMode = .week
    @State private var showInterleavingPattern = false
    @State private var expandedTopic: String? = nil
    
    enum ViewMode: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        
        var icon: String {
            switch self {
            case .day: return "1.square"
            case .week: return "7.square"
            case .month: return "calendar"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with controls
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Revision Schedule", systemImage: "calendar.badge.clock")
                        .font(.headline)
                    
                    Spacer()
                    
                    // View mode selector
                    Picker("View", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: mode.icon)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                
                // Exam countdown
                if let examDate = schedule.examDate {
                    ExamCountdownView(examDate: examDate)
                }
            }
            
            // Calendar view based on mode
            Group {
                switch viewMode {
                case .day:
                    DayScheduleView(
                        schedule: schedule,
                        selectedDate: $selectedDate,
                        expandedTopic: $expandedTopic
                    )
                case .week:
                    WeekScheduleView(
                        schedule: schedule,
                        selectedDate: $selectedDate
                    )
                case .month:
                    MonthScheduleView(
                        schedule: schedule,
                        selectedDate: $selectedDate
                    )
                }
            }
            .animation(.easeInOut, value: viewMode)
            
            // Spaced Intervals Display
            if !schedule.spacedIntervals.isEmpty {
                SpacedIntervalsView(intervals: schedule.spacedIntervals)
            }
            
            // Interleaving Pattern
            if let pattern = schedule.interleavingPattern, !pattern.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: { showInterleavingPattern.toggle() }) {
                        HStack {
                            Image(systemName: "shuffle")
                                .foregroundColor(.purple)
                            Text("Interleaving Pattern")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: showInterleavingPattern ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                    }
                    
                    if showInterleavingPattern {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Array(pattern.enumerated()), id: \.offset) { index, topic in
                                    Text(topic)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.purple.opacity(0.1))
                                        .cornerRadius(6)
                                        .overlay(
                                            Text("\(index + 1)")
                                                .font(.system(size: 8))
                                                .foregroundColor(.white)
                                                .padding(2)
                                                .background(Circle().fill(Color.purple))
                                                .offset(x: -4, y: -8),
                                            alignment: .topLeading
                                        )
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct ExamCountdownView: View {
    let examDate: Date
    
    var daysUntilExam: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: examDate).day ?? 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "hourglass")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Exam Date: \(examDate, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(daysUntilExam) days remaining")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(daysUntilExam < 7 ? .red : .primary)
            }
            
            Spacer()
            
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: progressPercent)
                    .stroke(
                        daysUntilExam < 7 ? Color.red : Color.green,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(progressPercent * 100))%")
                    .font(.system(size: 10))
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var progressPercent: CGFloat {
        // Calculate progress based on original study period
        let totalDays = 30.0 // Assuming 30-day study period
        let daysCompleted = totalDays - Double(daysUntilExam)
        return max(0, min(1, daysCompleted / totalDays))
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

struct DayScheduleView: View {
    let schedule: RevisionSchedule
    @Binding var selectedDate: Date
    @Binding var expandedTopic: String?
    
    var todaysSessions: [RevisionSession] {
        schedule.sessions.filter { session in
            Calendar.current.isDate(session.date, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date selector
            HStack {
                Button(action: {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(selectedDate, formatter: dayFormatter)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            
            // Sessions for the day
            if todaysSessions.isEmpty {
                Text("No revision scheduled for this day")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(todaysSessions) { session in
                        SessionCard(
                            session: session,
                            isExpanded: expandedTopic == session.id,
                            onTap: {
                                withAnimation {
                                    expandedTopic = expandedTopic == session.id ? nil : session.id
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
}

struct WeekScheduleView: View {
    let schedule: RevisionSchedule
    @Binding var selectedDate: Date
    
    var weekDays: [Date] {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return []
        }
        
        var days: [Date] = []
        var date = weekInterval.start
        
        for _ in 0..<7 {
            days.append(date)
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        }
        
        return days
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Week header
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    VStack(spacing: 4) {
                        Text(dayFormatter.string(from: day))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(.caption)
                            .fontWeight(Calendar.current.isDateInToday(day) ? .bold : .regular)
                            .foregroundColor(Calendar.current.isDateInToday(day) ? .blue : .primary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Sessions grid
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(weekDays, id: \.self) { day in
                        let sessions = schedule.sessions.filter {
                            Calendar.current.isDate($0.date, inSameDayAs: day)
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(Calendar.current.component(.day, from: day))")
                                .font(.caption)
                                .frame(width: 30)
                                .foregroundColor(.secondary)
                            
                            if sessions.isEmpty {
                                Text("—")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(sessions) { session in
                                        MiniSessionCard(session: session)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }
}

struct MonthScheduleView: View {
    let schedule: RevisionSchedule
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Month View")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Simplified month calendar
            CalendarGrid(
                schedule: schedule,
                selectedDate: $selectedDate
            )
        }
    }
}

struct CalendarGrid: View {
    let schedule: RevisionSchedule
    @Binding var selectedDate: Date
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            // Day headers
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            // Calendar days (simplified)
            ForEach(1...30, id: \.self) { day in
                let hasSession = schedule.sessions.contains { session in
                    Calendar.current.component(.day, from: session.date) == day
                }
                
                Text("\(day)")
                    .font(.caption)
                    .frame(width: 30, height: 30)
                    .background(hasSession ? Color.blue.opacity(0.2) : Color(.systemGray6))
                    .cornerRadius(6)
            }
        }
    }
}

struct SessionCard: View {
    let session: RevisionSession
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SessionTypeIcon(type: session.type)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.topics.joined(separator: ", "))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(isExpanded ? nil : 1)
                        
                        HStack(spacing: 8) {
                            Label("\(session.durationMinutes) min", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(session.type.capitalized)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(typeColor.opacity(0.2))
                                .foregroundColor(typeColor)
                                .cornerRadius(4)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        // Topics breakdown
                        ForEach(session.topics, id: \.self) { topic in
                            HStack(spacing: 6) {
                                Image(systemName: "book")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text(topic)
                                    .font(.caption)
                            }
                            .padding(6)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(6)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var typeColor: Color {
        switch session.type {
        case "new":
            return .green
        case "review":
            return .blue
        case "practice":
            return .purple
        default:
            return .gray
        }
    }
}

struct MiniSessionCard: View {
    let session: RevisionSession
    
    var body: some View {
        HStack(spacing: 4) {
            SessionTypeIcon(type: session.type)
                .font(.system(size: 10))
            
            Text(session.topics.first ?? "")
                .font(.system(size: 10))
                .lineLimit(1)
            
            if session.topics.count > 1 {
                Text("+\(session.topics.count - 1)")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
        .padding(4)
        .background(Color(.systemGray6))
        .cornerRadius(4)
    }
}

struct SessionTypeIcon: View {
    let type: String
    
    var body: some View {
        Image(systemName: icon)
            .foregroundColor(color)
    }
    
    private var icon: String {
        switch type {
        case "new":
            return "plus.circle"
        case "review":
            return "arrow.clockwise"
        case "practice":
            return "pencil.circle"
        default:
            return "circle"
        }
    }
    
    private var color: Color {
        switch type {
        case "new":
            return .green
        case "review":
            return .blue
        case "practice":
            return .purple
        default:
            return .gray
        }
    }
}

struct SpacedIntervalsView: View {
    let intervals: [String: [Int]]
    @State private var selectedTopic: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Spaced Repetition Intervals", systemImage: "clock.arrow.circlepath")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(intervals.keys.sorted()), id: \.self) { topic in
                        Button(action: { selectedTopic = topic }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(topic)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                
                                HStack(spacing: 2) {
                                    ForEach(intervals[topic] ?? [], id: \.self) { day in
                                        Text("\(day)d")
                                            .font(.system(size: 9))
                                            .padding(2)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(2)
                                    }
                                }
                            }
                            .padding(6)
                            .background(selectedTopic == topic ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

// Data Models
struct RevisionSchedule {
    let sessions: [RevisionSession]
    let spacedIntervals: [String: [Int]]
    let interleavingPattern: [String]?
    let examDate: Date?
}

struct RevisionSession: Identifiable {
    let id = UUID().uuidString
    let date: Date
    let topics: [String]
    let durationMinutes: Int
    let type: String // "new", "review", "practice"
}
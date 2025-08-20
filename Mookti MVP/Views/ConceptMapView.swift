import SwiftUI

struct ConceptMapView: View {
    let conceptMap: ConceptMap
    @State private var selectedNode: ConceptNode? = nil
    @State private var zoomScale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    @State private var showPrerequisites = false
    @State private var showApplications = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with controls
            HStack {
                Text("Concept Map")
                    .font(.headline)
                
                Spacer()
                
                // Zoom controls
                HStack(spacing: 8) {
                    Button(action: { 
                        withAnimation {
                            zoomScale = max(0.5, zoomScale - 0.2)
                        }
                    }) {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.caption)
                    }
                    
                    Text("\(Int(zoomScale * 100))%")
                        .font(.caption2)
                        .frame(width: 40)
                    
                    Button(action: { 
                        withAnimation {
                            zoomScale = min(2.0, zoomScale + 0.2)
                        }
                    }) {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.caption)
                    }
                    
                    Button(action: { 
                        withAnimation {
                            zoomScale = 1.0
                            dragOffset = .zero
                        }
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // Map Canvas
            GeometryReader { geometry in
                ZStack {
                    // Background grid
                    GridPattern()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    
                    // Concept map visualization
                    ConceptMapCanvas(
                        nodes: conceptMap.nodes,
                        edges: conceptMap.edges,
                        selectedNode: $selectedNode,
                        geometry: geometry
                    )
                    .scaleEffect(zoomScale)
                    .offset(dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = CGSize(
                                    width: value.translation.width + dragOffset.width,
                                    height: value.translation.height + dragOffset.height
                                )
                            }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .clipped()
            }
            .frame(height: 300)
            
            // Selected Node Details
            if let node = selectedNode {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        NodeTypeIcon(type: node.type)
                        Text(node.label)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                    
                    // Show connections
                    let connections = conceptMap.edges.filter { $0.from == node.id || $0.to == node.id }
                    if !connections.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Connections:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(connections, id: \.from) { edge in
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(edge.relationship)
                                        .font(.caption)
                                    Text(edge.to == node.id ? edge.from : edge.to)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(4)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            
            // Prerequisites & Applications
            HStack(spacing: 12) {
                // Prerequisites
                if let prerequisites = conceptMap.prerequisites, !prerequisites.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Button(action: { showPrerequisites.toggle() }) {
                            HStack {
                                Image(systemName: "bookmark")
                                    .foregroundColor(.orange)
                                Text("Prerequisites (\(prerequisites.count))")
                                    .font(.caption)
                                Image(systemName: showPrerequisites ? "chevron.up" : "chevron.down")
                                    .font(.caption2)
                            }
                        }
                        
                        if showPrerequisites {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(prerequisites, id: \.self) { prereq in
                                    HStack(spacing: 6) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 4))
                                            .foregroundColor(.orange)
                                        Text(prereq)
                                            .font(.caption)
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color.orange.opacity(0.05))
                            .cornerRadius(6)
                        }
                    }
                }
                
                // Applications
                if let applications = conceptMap.applications, !applications.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Button(action: { showApplications.toggle() }) {
                            HStack {
                                Image(systemName: "app.badge")
                                    .foregroundColor(.green)
                                Text("Applications (\(applications.count))")
                                    .font(.caption)
                                Image(systemName: showApplications ? "chevron.up" : "chevron.down")
                                    .font(.caption2)
                            }
                        }
                        
                        if showApplications {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(applications, id: \.self) { app in
                                    HStack(spacing: 6) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 4))
                                            .foregroundColor(.green)
                                        Text(app)
                                            .font(.caption)
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color.green.opacity(0.05))
                            .cornerRadius(6)
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

struct ConceptMapCanvas: View {
    let nodes: [ConceptNode]
    let edges: [ConceptEdge]
    @Binding var selectedNode: ConceptNode?
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            // Draw edges first (behind nodes)
            ForEach(edges, id: \.from) { edge in
                if let fromNode = nodes.first(where: { $0.id == edge.from }),
                   let toNode = nodes.first(where: { $0.id == edge.to }) {
                    EdgeView(
                        from: nodePosition(fromNode),
                        to: nodePosition(toNode),
                        label: edge.relationship
                    )
                }
            }
            
            // Draw nodes on top
            ForEach(nodes) { node in
                NodeView(
                    node: node,
                    isSelected: selectedNode?.id == node.id,
                    position: nodePosition(node)
                ) {
                    withAnimation {
                        selectedNode = node
                    }
                }
            }
        }
    }
    
    private func nodePosition(_ node: ConceptNode) -> CGPoint {
        // Simple circular layout - can be improved with force-directed layout
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        let radius = min(centerX, centerY) * 0.7
        
        if node.id == "central" {
            return CGPoint(x: centerX, y: centerY)
        }
        
        let index = nodes.firstIndex(where: { $0.id == node.id }) ?? 0
        let angle = (Double(index) / Double(nodes.count)) * 2 * .pi
        
        return CGPoint(
            x: centerX + radius * cos(angle),
            y: centerY + radius * sin(angle)
        )
    }
}

struct NodeView: View {
    let node: ConceptNode
    let isSelected: Bool
    let position: CGPoint
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                NodeTypeIcon(type: node.type)
                    .font(.caption)
                
                Text(node.label)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 80)
            }
            .padding(8)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color(.systemGray3), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(8)
            .shadow(radius: 2)
        }
        .position(position)
    }
}

struct EdgeView: View {
    let from: CGPoint
    let to: CGPoint
    let label: String
    
    var body: some View {
        ZStack {
            // Line
            Path { path in
                path.move(to: from)
                path.addLine(to: to)
            }
            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            
            // Arrow head
            Path { path in
                let angle = atan2(to.y - from.y, to.x - from.x)
                let arrowLength: CGFloat = 10
                let arrowAngle: CGFloat = .pi / 6
                
                let arrowPoint1 = CGPoint(
                    x: to.x - arrowLength * cos(angle - arrowAngle),
                    y: to.y - arrowLength * sin(angle - arrowAngle)
                )
                let arrowPoint2 = CGPoint(
                    x: to.x - arrowLength * cos(angle + arrowAngle),
                    y: to.y - arrowLength * sin(angle + arrowAngle)
                )
                
                path.move(to: to)
                path.addLine(to: arrowPoint1)
                path.move(to: to)
                path.addLine(to: arrowPoint2)
            }
            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            
            // Label
            Text(label)
                .font(.system(size: 9))
                .padding(2)
                .background(Color(.systemBackground).opacity(0.9))
                .position(
                    x: (from.x + to.x) / 2,
                    y: (from.y + to.y) / 2
                )
        }
    }
}

struct NodeTypeIcon: View {
    let type: ConceptNodeType
    
    var body: some View {
        Image(systemName: iconName)
            .foregroundColor(iconColor)
    }
    
    private var iconName: String {
        switch type {
        case .concept:
            return "brain"
        case .example:
            return "doc.text"
        case .application:
            return "app.badge"
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .concept:
            return .blue
        case .example:
            return .purple
        case .application:
            return .green
        }
    }
}

struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let gridSize: CGFloat = 20
        
        // Vertical lines
        for x in stride(from: 0, through: rect.width, by: gridSize) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        
        // Horizontal lines
        for y in stride(from: 0, through: rect.height, by: gridSize) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        
        return path
    }
}

// Data Models
struct ConceptMap {
    let nodes: [ConceptNode]
    let edges: [ConceptEdge]
    let prerequisites: [String]?
    let applications: [String]?
}

struct ConceptNode: Identifiable {
    let id: String
    let label: String
    let type: ConceptNodeType
}

enum ConceptNodeType {
    case concept
    case example
    case application
}

struct ConceptEdge {
    let from: String
    let to: String
    let relationship: String
}
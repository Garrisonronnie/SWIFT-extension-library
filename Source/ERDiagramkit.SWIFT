import Foundation
import UIKit
import PDFKit

public class ERDiagramKit: UIView {
    
    public var schema: Schema? {
        didSet { reloadDiagram() }
    }
    
    private var nodes: [DiagramNode] = []
    private var edges: [DiagramEdge] = []

    // MARK: - Public API
    
    public init(frame: CGRect, schema: Schema?) {
        self.schema = schema
        super.init(frame: frame)
        setupGestureRecognizers()
        reloadDiagram()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    
    /// Export diagram to PDF or SVG
    public func export(to format: String) -> Data? {
        switch format.lowercased() {
        case "pdf": return exportToPDF()
        case "svg": return exportToSVG()
        default: return nil
        }
    }
    
    // MARK: - Diagram Reload
    
    private func reloadDiagram() {
        guard let schema = schema else { return }
        nodes.removeAll()
        edges.removeAll()
        
        // Build nodes & edges from schema
        for (_, table) in schema.tables {
            nodes.append(DiagramNode(table: table))
        }
        for (_, table) in schema.tables {
            for col in table.columns where col.isForeignKey {
                if let targetNode = nodes.first(where: { $0.name == col.foreignKeyTargetTable }) {
                    edges.append(DiagramEdge(from: table.name, to: targetNode.name))
                }
            }
        }
        applyAutoLayout()
        setNeedsDisplay()
    }
    
    // MARK: - Auto-layout
    
    private func applyAutoLayout() {
        let padding: CGFloat = 50
        var xOffset: CGFloat = padding
        var yOffset: CGFloat = padding
        for node in nodes {
            node.frame = CGRect(x: xOffset, y: yOffset, width: 150, height: 80)
            yOffset += 120
            if yOffset > bounds.height - 100 {
                yOffset = padding
                xOffset += 200
            }
        }
    }
    
    // MARK: - Zoom & Filter
    
    private func setupGestureRecognizers() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        self.addGestureRecognizer(pinch)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        transform = transform.scaledBy(x: gesture.scale, y: gesture.scale)
        gesture.scale = 1
    }
    
    public func filterNodes(matching keyword: String) {
        nodes.forEach { $0.isHidden = !$0.name.contains(keyword) }
        setNeedsDisplay()
    }
    
    // MARK: - Rendering
    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.clear(rect)
        
        // Draw edges
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.5)
        for edge in edges {
            if let fromNode = nodes.first(where: { $0.name == edge.from }),
               let toNode = nodes.first(where: { $0.name == edge.to }) {
                context.move(to: fromNode.center)
                context.addLine(to: toNode.center)
                context.strokePath()
            }
        }
        
        // Draw nodes
        for node in nodes where !node.isHidden {
            context.setFillColor(UIColor.systemBlue.cgColor)
            context.fill(node.frame)
            let text = NSString(string: node.name)
            text.draw(in: node.frame.insetBy(dx: 5, dy: 5),
                      withAttributes: [.foregroundColor: UIColor.white,
                                       .font: UIFont.systemFont(ofSize: 14)])
        }
    }
    
    // MARK: - Export Helpers
    
    private func exportToPDF() -> Data? {
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        return renderer.pdfData { ctx in
            ctx.beginPage()
            layer.render(in: ctx.cgContext)
        }
    }
    
    private func exportToSVG() -> Data? {
        var svg = "<svg width=\"\(Int(bounds.width))\" height=\"\(Int(bounds.height))\" xmlns=\"http://www.w3.org/2000/svg\">"
        for node in nodes where !node.isHidden {
            svg += "<rect x=\"\(Int(node.frame.origin.x))\" y=\"\(Int(node.frame.origin.y))\" width=\"\(Int(node.frame.width))\" height=\"\(Int(node.frame.height))\" style=\"fill:blue;stroke:black;stroke-width:1\" />"
            svg += "<text x=\"\(Int(node.frame.origin.x + 5))\" y=\"\(Int(node.frame.origin.y + 20))\" fill=\"white\">\(node.name)</text>"
        }
        svg += "</svg>"
        return svg.data(using: .utf8)
    }
}

// MARK: - Node & Edge Models

fileprivate class DiagramNode {
    let name: String
    var frame: CGRect = .zero
    var isHidden: Bool = false
    
    init(table: Table) { self.name = table.name }
    var center: CGPoint { CGPoint(x: frame.midX, y: frame.midY) }
}

fileprivate struct DiagramEdge {
    let from: String
    let to: String
}

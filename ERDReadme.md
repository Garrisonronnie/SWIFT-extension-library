# ERDiagramKit

ERDiagramKit is a **standalone Swift module** that allows you to **generate, visualize, and export Entity-Relationship (ER) diagrams** from SQL schema files. It is designed to be modular, legal, and fully compatible with other Swift projects, including CLI tools.

---

## ✅ Features

- **Auto-layout ER diagrams**: Nodes are positioned automatically to avoid overlap.
- **Interactive zoom & filter**: Pinch to zoom; filter nodes by name.
- **Export**: Generate **PDF** or **SVG** diagrams.
- **Standalone or integrated**: Works alone or alongside your existing Swift libraries.
- **Original logic**: All diagram rendering, layout, and exporting is fully original and copyright safe.
- **CLI support**: Quickly generate diagrams from the terminal without writing code.

---

## 💡 Usage Examples

### 1. Basic Swift Usage

Import the module and create a diagram from a SQL schema file:

```swift
import ERDiagramKit

do {
    let schema = try SQLParser().parseSchema(fromFile: "my_schema.sql")
    let diagram = ERDiagramKit(frame: CGRect(x: 0, y: 0, width: 2000, height: 2000), schema: schema)

    // Export to PDF
    if let pdfData = diagram.export(to: "pdf") {
        try pdfData.write(to: URL(fileURLWithPath: "my_er_diagram.pdf"))
    }

    // Export to SVG
    if let svgData = diagram.export(to: "svg") {
        try svgData.write(to: URL(fileURLWithPath: "my_er_diagram.svg"))
    }

    print("ER diagram successfully generated.")
} catch {
    print("Error generating diagram: \(error)")
}
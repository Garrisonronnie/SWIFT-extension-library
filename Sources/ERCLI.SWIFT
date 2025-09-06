import Foundation
import UIKit
import ERDiagramKit

enum ERCLI {
    static func run() {
        let args = CommandLine.arguments
        guard args.count >= 3 else { printUsage(); return }

        let cmd = args[1].lowercased()
        let inputSQL = args[2]
        let outputFile = args.count >= 4 ? args[3] : "erdiagram_output.pdf"
        let format = args.count >= 5 ? args[4].lowercased() : "pdf"

        do {
            switch cmd {
            case "generate": try generateDiagram(from: inputSQL, output: outputFile, format: format)
            case "--help", "-h", "help": printUsage()
            default:
                print("Unknown command: \(cmd)"); printUsage()
            }
        } catch { print("Error: \(error)") }
    }

    static func generateDiagram(from sqlFile: String, output: String, format: String) throws {
        let parser = SQLParser() // DDiffLib parser
        let schema = try parser.parseSchema(fromFile: sqlFile)
        let diagram = ERDiagramKit(frame: CGRect(x: 0, y: 0, width: 2000, height: 2000), schema: schema)
        guard let data = diagram.export(to: format) else {
            print("Failed to export diagram in format \(format)"); return
        }
        try data.write(to: URL(fileURLWithPath: output))
        print("ER diagram generated at \(output) in \(format.uppercased()) format")
    }

    static func printUsage() {
        print("""
        ERDiagramCLI
        Usage:
          ercli generate input.sql [output.pdf|svg] [format: pdf|svg]
        Example:
          ercli generate my_schema.sql erdiagram.pdf pdf
        """)
    }
}

ERCLI.run()

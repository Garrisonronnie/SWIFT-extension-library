import Foundation
import DDiffLib

enum CLI {
    static func run() {
        let args = CommandLine.arguments
        guard args.count >= 2 else { printUsage(); return }
        let cmd = args[1].lowercased()

        do {
            switch cmd {
            case "diff":
                guard args.count >= 4 else { fatal("Usage: ddiff diff old.sql new.sql") }
                try doDiff(oldPath: args[2], newPath: args[3])
            case "migrate":
                guard args.count >= 4 else { fatal("Usage: ddiff migrate old.sql new.sql [--dry-run] [--dialect sqlite|postgres|mysql]") }
                let dry = args.contains("--dry-run")
                let dialect = parseDialect(args: args)
                try doMigrate(oldPath: args[2], newPath: args[3], dryRun: dry, dialect: dialect)
            case "rollback":
                guard args.count >= 4 else { fatal("Usage: ddiff rollback old.sql new.sql [--table tableName] [--dialect sqlite|postgres|mysql]") }
                let dialect = parseDialect(args: args)
                let tableArg = parseOptionValue(args: args, option: "--table")
                try doRollback(oldPath: args[2], newPath: args[3], table: tableArg, dialect: dialect)
            case "test-migrate":
                guard args.count >= 4 else { fatal("Usage: ddiff test-migrate old.sql new.sql") }
                try doTestMigration(oldPath: args[2], newPath: args[3])
            case "visualize":
                guard args.count >= 4 else { fatal("Usage: ddiff visualize old.sql new.sql [--format dot|ascii]") }
                let format = parseOptionValue(args: args, option: "--format") ?? "dot"
                try doVisualize(oldPath: args[2], newPath: args[3], format: format)
            case "--help", "-h", "help":
                printUsage()
            default:
                print("Unknown command: \(cmd)")
                printUsage()
            }
        } catch {
            fputs("Error: \(error)\n", stderr)
        }
    }

    // MARK: - Argument Utilities
    static func parseDialect(args: [String]) -> SQLDialect {
        if let v = parseOptionValue(args: args, option: "--dialect") {
            switch v.lowercased() {
            case "sqlite": return .sqlite
            case "postgres": return .postgres
            case "mysql": return .mysql
            default: return .generic
            }
        }
        return .generic
    }

    static func parseOptionValue(args: [String], option: String) -> String? {
        guard let idx = args.firstIndex(of: option), args.count > idx + 1 else { return nil }
        return args[idx + 1]
    }

    // MARK: - Commands
    static func doDiff(oldPath: String, newPath: String) throws {
        let parser = SQLParser()
        let old = try parser.parseSchema(fromFile: oldPath)
        let new = try parser.parseSchema(fromFile: newPath)
        let engine = DiffEngine()
        let diff = engine.diff(old: old, new: new)
        printDiff(diff)
    }

    static func doMigrate(oldPath: String, newPath: String, dryRun: Bool, dialect: SQLDialect) throws {
        let parser = SQLParser()
        let old = try parser.parseSchema(fromFile: oldPath)
        let new = try parser.parseSchema(fromFile: newPath)
        let engine = DiffEngine()
        let diff = engine.diff(old: old, new: new)
        let gen = MigrationGenerator()
        let sqls = gen.generateMigrationSQL(from: diff, dialect: dialect)

        if dryRun {
            print("=== Dry-run migration SQL ===")
            sqls.forEach { print($0) }
            return
        }

        if dialect == .sqlite {
            let runner = MigrationTestRunner()
            let (success, log) = runner.runMigrationSQL(sqls)
            print(log)
            print("Migration applied: \(success)")
        } else {
            print("Generated SQL for dialect \(dialect):")
            sqls.forEach { print($0) }
        }
    }

    static func doRollback(oldPath: String, newPath: String, table: String?, dialect: SQLDialect) throws {
        let parser = SQLParser()
        let old = try parser.parseSchema(fromFile: oldPath)
        let new = try parser.parseSchema(fromFile: newPath)
        let engine = DiffEngine()
        var diff = engine.diff(old: old, new: new)

        // selective rollback
        if let t = table {
            let tkey = t.lowercased()
            diff.columnAdditions = diff.columnAdditions.filter { $0.table == tkey }
            diff.columnRemovals = diff.columnRemovals.filter { $0.table == tkey }
            diff.columnChanges = diff.columnChanges.filter { $0.table == tkey }
            diff.tablesAdded = diff.tablesAdded.filter { $0.name.lowercased() == tkey }
            diff.tablesRemoved = diff.tablesRemoved.filter { $0.name.lowercased() == tkey }
        }

        let gen = MigrationGenerator()
        let roll = gen.generateRollbackSQL(from: diff, dialect: dialect)
        print("--- Rollback SQL / Instructions ---")
        roll.forEach { print($0) }
    }

    static func doTestMigration(oldPath: String, newPath: String) throws {
        let parser = SQLParser()
        let old = try parser.parseSchema(fromFile: oldPath)
        let new = try parser.parseSchema(fromFile: newPath)
        let engine = DiffEngine()
        let diff = engine.diff(old: old, new: new)
        let gen = MigrationGenerator()
        let sqls = gen.generateMigrationSQL(from: diff, dialect: .sqlite)
        let runner = MigrationTestRunner()
        let (success, log) = runner.runMigrationSQL(sqls)
        print(log)
        print("Test migration success: \(success)")
    }

    static func doVisualize(oldPath: String, newPath: String, format: String) throws {
        let parser = SQLParser()
        let old = try parser.parseSchema(fromFile: oldPath)
        let new = try parser.parseSchema(fromFile: newPath)
        let engine = DiffEngine()
        let diff = engine.diff(old: old, new: new)
        switch format.lowercased() {
        case "dot": print(generateDOT(old: old, new: new, diff: diff))
        default: printASCII(old: old, new: new, diff: diff)
        }
    }

    // MARK: - Visualization
    static func generateDOT(old: Schema, new: Schema, diff: SchemaDiff) -> String {
        var out = "digraph schema {\nrankdir=LR;\n"
        func tableNode(_ t: Table, color: String) -> String {
            let cols = t.columns.map { "\\l\($0.name) : \($0.type)" }.joined()
            return "\"\(t.name)\" [label=\"\(t.name)\\n\(cols)\\l\" shape=record, style=filled, fillcolor=\(color)];\n"
        }
        for (_, t) in old.tables { out += tableNode(t, color: "#ffffff") }
        for t in diff.tablesAdded { out += tableNode(t, color: "#ccffcc") }
        for t in diff.tablesRemoved { out += tableNode(t, color: "#ffcccc") }
        out += "}\n"
        return out
    }

    static func printASCII(old: Schema, new: Schema, diff: SchemaDiff) {
        print("=== Tables Added ==="); diff.tablesAdded.forEach { print("- \($0.name)") }
        print("=== Tables Removed ==="); diff.tablesRemoved.forEach { print("- \($0.name)") }
        print("=== Columns Added ==="); diff.columnAdditions.forEach { print("- \($0.table).\($0.column.name) : \($0.column.type)") }
        print("=== Columns Removed ==="); diff.columnRemovals.forEach { print("- \($0.table).\($0.column.name) : \($0.column.type)") }
        print("=== Columns Changed ==="); diff.columnChanges.forEach { print("- \($0.table).\($0.old.name) : \($0.old.type) -> \($0.new.type)") }
    }

    static func printDiff(_ diff: SchemaDiff) { printASCII(old: Schema(), new: Schema(), diff: diff) }

    // MARK: - Utilities
    static func fatal(_ msg: String) -> Never { fputs(msg + "\n", stderr); exit(1) }

    static func printUsage() {
        let usage = """
        SWIFT DDiffExtensions (ddiff)
        Usage:
          ddiff diff old.sql new.sql
          ddiff migrate old.sql new.sql [--dry-run] [--dialect sqlite|postgres|mysql]
          ddiff rollback old.sql new.sql [--table tableName] [--dialect sqlite|postgres|mysql]
          ddiff test-migrate old.sql new.sql
          ddiff visualize old.sql new.sql [--format dot|ascii]
        """
        print(usage)
    }
}

// Run CLI
CLI.run()
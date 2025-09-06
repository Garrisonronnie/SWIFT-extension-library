import Foundation

public enum ParserError: Error, CustomStringConvertible {
    case fileNotFound(String)
    case invalidSQL(String)

    public var description: String {
        switch self {
        case .fileNotFound(let path): return "File not found: \(path)"
        case .invalidSQL(let sql): return "Invalid SQL snippet: \(sql.prefix(100))..."
        }
    }
}

public final class SQLParser {
    public init() {}

    // MARK: - Parse From File
    public func parseSchema(fromFile path: String) throws -> Schema {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            throw ParserError.fileNotFound(path)
        }
        let contents = try String(contentsOf: url, encoding: .utf8)
        return parseSchema(from: contents)
    }

    // MARK: - Parse From SQL
    public func parseSchema(from sql: String) -> Schema {
        var schema = Schema()

        // Regex: CREATE TABLE [optional schema].[tableName] (...)
        let pattern = #"(?is)CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:`?([\w]+)`?\.)?`?([\w$]+)`?\s*\((.*?)\)\s*;"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return schema
        }

        let ns = sql as NSString
        regex.enumerateMatches(in: sql, options: [], range: NSRange(location:0, length: ns.length)) { match, _, _ in
            guard let match = match, match.numberOfRanges >= 4 else { return }
            let tableName = ns.substring(with: match.range(at: 2))
            let body = ns.substring(with: match.range(at: 3))

            let columns = parseColumns(from: body)
            let fks = parseForeignKeys(from: body)
            let indexes = parseIndexes(from: body)

            let table = Table(name: tableName, columns: columns, indexes: indexes, foreignKeys: fks)
            schema.tables[tableName.lowercased()] = table
        }

        return schema
    }

    // MARK: - Column Parser
    private func parseColumns(from body: String) -> [Column] {
        var columns: [Column] = []

        // Split by commas at top level (ignoring commas in parens)
        var depth = 0
        var current = ""
        for char in body {
            if char == "(" { depth += 1 }
            if char == ")" { depth -= 1 }
            if char == "," && depth == 0 {
                processColumnDef(current, into: &columns)
                current = ""
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            processColumnDef(current, into: &columns)
        }
        return columns
    }

    private func processColumnDef(_ raw: String, into columns: inout [Column]) {
        let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return }

        let lower = line.lowercased()
        // Skip table-level constraints
        if lower.starts(with: "primary key") || lower.starts(with: "unique")
            || lower.starts(with: "constraint") || lower.starts(with: "foreign key") {
            return
        }

        // Tokenize
        let tokens = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        guard tokens.count >= 2 else { return }

        let colName = tokens[0].trimmingCharacters(in: CharacterSet(charactersIn: "`\"[]"))
        let colType = tokens[1...].joined(separator: " ") // preserves VARCHAR(255), DECIMAL(10,2), etc.

        let isPK = lower.contains("primary key")
        let isNN = lower.contains("not null")
        let defaultValue = extractDefault(from: line)

        let col = Column(name: colName, type: colType, isPrimaryKey: isPK, isNotNull: isNN, defaultValue: defaultValue)
        columns.append(col)
    }

    private func extractDefault(from definition: String) -> String? {
        let regex = try? NSRegularExpression(pattern: #"DEFAULT\s+(['"\w\d$begin:math:text$$end:math:text$]+)"#, options: .caseInsensitive)
        guard let match = regex?.firstMatch(in: definition, options: [], range: NSRange(location: 0, length: definition.count)) else {
            return nil
        }
        let ns = definition as NSString
        return ns.substring(with: match.range(at: 1))
    }

    // MARK: - Foreign Key Parser
    private func parseForeignKeys(from body: String) -> [ForeignKey] {
        var fks: [ForeignKey] = []
        let pattern = #"FOREIGN\s+KEY\s*\(`?(\w+)`?\)\s+REFERENCES\s+`?(\w+)`?\s*\(`?(\w+)`?\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return fks
        }
        let ns = body as NSString
        regex.enumerateMatches(in: body, options: [], range: NSRange(location: 0, length: ns.length)) { match, _, _ in
            guard let match = match, match.numberOfRanges == 4 else { return }
            let col = ns.substring(with: match.range(at: 1))
            let refTable = ns.substring(with: match.range(at: 2))
            let refCol = ns.substring(with: match.range(at: 3))
            let fk = ForeignKey(name: "fk_\(col)_\(refTable)", column: col, refTable: refTable, refColumn: refCol)
            fks.append(fk)
        }
        return fks
    }

    // MARK: - Index Parser (very minimal)
    private func parseIndexes(from body: String) -> [Index] {
        var indexes: [Index] = []
        let pattern = #"(?i)(UNIQUE\s+)?KEY\s+`?(\w+)`?\s*\((.*?)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return indexes
        }
        let ns = body as NSString
        regex.enumerateMatches(in: body, options: [], range: NSRange(location: 0, length: ns.length)) { match, _, _ in
            guard let match = match, match.numberOfRanges == 4 else { return }
            let isUnique = ns.substring(with: match.range(at: 1)).lowercased().contains("unique")
            let name = ns.substring(with: match.range(at: 2))
            let cols = ns.substring(with: match.range(at: 3))
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "` \"")) }
            indexes.append(Index(name: name, columns: cols, isUnique: isUnique))
        }
        return indexes
    }
}
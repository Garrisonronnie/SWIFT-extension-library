import Foundation
import SQLite3

public final class MigrationTestRunner {
    public init() {}

    /// Apply migration SQL statements to an in-memory SQLite DB.
    /// Returns tuple `(success: Bool, log: String)` for results and debug info.
    public func runMigrationSQL(_ sqls: [String]) -> (success: Bool, log: String) {
        var log = ""
        var db: OpaquePointer? = nil
        
        // Open in-memory database
        guard sqlite3_open(":memory:", &db) == SQLITE_OK else {
            return (false, "Unable to open in-memory SQLite database.")
        }
        defer { sqlite3_close(db) }

        for stmt in sqls {
            let sql = stmt.trimmingCharacters(in: .whitespacesAndNewlines)
            // Skip empty lines or comments
            if sql.isEmpty || sql.hasPrefix("--") {
                log += "[SKIP] \(sql)\n"
                continue
            }

            // Execute statement
            var errmsg: UnsafeMutablePointer<Int8>? = nil
            if sqlite3_exec(db, sql, nil, nil, &errmsg) != SQLITE_OK {
                let message = errmsg != nil ? String(cString: errmsg!) : "Unknown SQLite error"
                log += "[ERROR] Failed executing:\n  \(sql)\n -> \(message)\n"
                return (false, log)
            } else {
                log += "[OK] \(sql)\n"
            }
        }

        // Optional: verify schema integrity after migration
        if let schemaLog = checkSchema(db: db) {
            log += schemaLog
        }

        return (true, log)
    }

    /// Optional helper to verify schema in memory (tables & columns)
    private func checkSchema(db: OpaquePointer?) -> String? {
        guard let db = db else { return nil }
        var log = "\n=== Schema Verification ===\n"
        let query = "SELECT name FROM sqlite_master WHERE type='table';"
        var stmt: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let cname = sqlite3_column_text(stmt, 0) {
                    let tableName = String(cString: cname)
                    log += "Table: \(tableName)\n"
                    // List columns
                    let colQuery = "PRAGMA table_info(\(tableName));"
                    var colStmt: OpaquePointer? = nil
                    if sqlite3_prepare_v2(db, colQuery, -1, &colStmt, nil) == SQLITE_OK {
                        while sqlite3_step(colStmt) == SQLITE_ROW {
                            let colName = String(cString: sqlite3_column_text(colStmt, 1))
                            let colType = String(cString: sqlite3_column_text(colStmt, 2))
                            let notNull = sqlite3_column_int(colStmt, 3) == 1
                            log += "  - \(colName) : \(colType)\(notNull ? " NOT NULL" : "")\n"
                        }
                        sqlite3_finalize(colStmt)
                    }
                }
            }
            sqlite3_finalize(stmt)
        }
        return log
    }
}

import Foundation

public enum SQLDialect {
    case sqlite
    case postgres
    case mysql
    case generic

    public func quoteIdentifier(_ name: String) -> String {
        switch self {
        case .sqlite, .mysql, .generic: return "`\(name)`"
        case .postgres: return "\"\(name)\""
        }
    }
}

public final class MigrationGenerator {
    public init() {}

    // MARK: - Generate Forward Migration SQL
    public func generateMigrationSQL(from diff: SchemaDiff, dialect: SQLDialect = .generic, includeTransaction: Bool = false, metadataVersion: Int? = nil) -> [String] {
        var sqls: [String] = []

        if includeTransaction { sqls.append("-- BEGIN TRANSACTION;") }

        // Tables Added
        for t in diff.tablesAdded {
            var colDefs = t.columns.map { col in
                var s = "\(dialect.quoteIdentifier(col.name)) \(col.type)"
                if col.isPrimaryKey { s += " PRIMARY KEY" }
                if col.isNotNull { s += " NOT NULL" }
                if let def = col.defaultValue { s += " DEFAULT \(def)" }
                return s
            }
            let create = "-- Create table \(t.name)\nCREATE TABLE \(dialect.quoteIdentifier(t.name)) (\(colDefs.joined(separator: ", ")));"
            sqls.append(create)
        }

        // Tables Removed
        for t in diff.tablesRemoved {
            sqls.append("-- Drop table \(t.name)\nDROP TABLE IF EXISTS \(dialect.quoteIdentifier(t.name));")
        }

        // Column Additions
        for add in diff.columnAdditions {
            let stmt = "-- Add column \(add.column.name) to \(add.table)\nALTER TABLE \(dialect.quoteIdentifier(add.table)) ADD COLUMN \(dialect.quoteIdentifier(add.column.name)) \(add.column.type)\(add.column.isNotNull ? " NOT NULL" : "")\(add.column.defaultValue.map { " DEFAULT \($0)" } ?? "");"
            sqls.append(stmt)
        }

        // Column Changes
        for change in diff.columnChanges {
            switch dialect {
            case .sqlite:
                sqls.append("-- SQLite: manual rebuild required for column change \(change.old.name) → \(change.new.name) in table \(change.table)")
                sqls.append(MigrationGenerator.rebuildTableSQL(tableName: change.table, removeColumn: change.old.name))
            case .postgres, .mysql, .generic:
                sqls.append("-- Change column \(change.old.name) to \(change.new.type) in \(change.table)\nALTER TABLE \(dialect.quoteIdentifier(change.table)) ALTER COLUMN \(dialect.quoteIdentifier(change.new.name)) TYPE \(change.new.type);")
            }
        }

        // Column Removals
        for rem in diff.columnRemovals {
            switch dialect {
            case .sqlite:
                sqls.append("-- SQLite: manual rebuild required to remove column \(rem.column.name) from table \(rem.table)")
                sqls.append(MigrationGenerator.rebuildTableSQL(tableName: rem.table, removeColumn: rem.column.name))
            default:
                sqls.append("-- Remove column \(rem.column.name) from table \(rem.table)\nALTER TABLE \(dialect.quoteIdentifier(rem.table)) DROP COLUMN \(dialect.quoteIdentifier(rem.column.name));")
            }
        }

        // Indexes
        for add in diff.indexAdditions {
            sqls.append("-- Add index \(add.index.name) on table \(add.table)\nCREATE\(add.index.isUnique ? " UNIQUE" : "") INDEX \(dialect.quoteIdentifier(add.index.name)) ON \(dialect.quoteIdentifier(add.table)) (\(add.index.columns.map { dialect.quoteIdentifier($0) }.joined(separator: ", ")));")
        }
        for rem in diff.indexRemovals {
            sqls.append("-- Remove index \(rem.index.name) from table \(rem.table)\nDROP INDEX IF EXISTS \(dialect.quoteIdentifier(rem.index.name));")
        }

        // Foreign Keys
        for add in diff.foreignKeyAdditions {
            sqls.append("-- Add foreign key \(add.fk.name) on \(add.table)(\(add.fk.column)) referencing \(add.fk.refTable)(\(add.fk.refColumn))")
        }
        for rem in diff.foreignKeyRemovals {
            sqls.append("-- Remove foreign key \(rem.fk.name) from \(rem.table)")
        }

        // Optional metadata version
        if let version = metadataVersion {
            sqls.append("-- Update migration version\nINSERT INTO migration_version(version, applied_at) VALUES(\(version), CURRENT_TIMESTAMP);")
        }

        if includeTransaction { sqls.append("-- COMMIT;") }
        return sqls
    }

    // MARK: - Generate Rollback SQL
    public func generateRollbackSQL(from diff: SchemaDiff, dialect: SQLDialect = .generic, includeTransaction: Bool = false) -> [String] {
        var sqls: [String] = []

        if includeTransaction { sqls.append("-- BEGIN TRANSACTION;") }

        // Reverse operations
        for add in diff.columnAdditions {
            switch dialect {
            case .sqlite:
                sqls.append("-- SQLite rollback to remove column `\(add.column.name)` from \(add.table)` requires rebuild")
                sqls.append(MigrationGenerator.rebuildTableSQL(tableName: add.table, removeColumn: add.column.name))
            default:
                sqls.append("-- Drop column \(add.column.name) from \(add.table)\nALTER TABLE \(dialect.quoteIdentifier(add.table)) DROP COLUMN \(dialect.quoteIdentifier(add.column.name));")
            }
        }

        for change in diff.columnChanges {
            sqls.append("-- Revert column \(change.new.name) to original type \(change.old.type) in \(change.table)\nALTER TABLE \(dialect.quoteIdentifier(change.table)) ALTER COLUMN \(dialect.quoteIdentifier(change.old.name)) TYPE \(change.old.type);")
        }

        for rem in diff.columnRemovals {
            sqls.append("-- Recreate removed column \(rem.column.name) in \(rem.table)\nALTER TABLE \(dialect.quoteIdentifier(rem.table)) ADD COLUMN \(dialect.quoteIdentifier(rem.column.name)) \(rem.column.type)\(rem.column.isNotNull ? " NOT NULL /* default required */" : "")\(rem.column.defaultValue.map { " DEFAULT \($0)" } ?? "");")
        }

        for t in diff.tablesAdded {
            sqls.append("-- Drop added table \(t.name)\nDROP TABLE IF EXISTS \(dialect.quoteIdentifier(t.name));")
        }

        for t in diff.tablesRemoved {
            sqls.append("-- Table \(t.name) removed; recreate manually using original CREATE TABLE")
        }

        for add in diff.indexAdditions {
            sqls.append("-- Drop index \(add.index.name) from table \(add.table)\nDROP INDEX IF EXISTS \(dialect.quoteIdentifier(add.index.name));")
        }
        for rem in diff.indexRemovals {
            sqls.append("-- Recreate index \(rem.index.name) manually on table \(rem.table)")
        }

        for add in diff.foreignKeyAdditions {
            sqls.append("-- Drop foreign key \(add.fk.name) on table \(add.table) manually")
        }
        for rem in diff.foreignKeyRemovals {
            sqls.append("-- Add foreign key \(rem.fk.name) on table \(rem.table) manually")
        }

        if includeTransaction { sqls.append("-- COMMIT;") }
        return sqls
    }

    // MARK: - SQLite Table Rebuild Helper
    public static func rebuildTableSQL(tableName: String, removeColumn: String) -> String {
        return """
CREATE TABLE _\(tableName)_new AS SELECT * FROM \(tableName) WHERE 0; -- create empty new table; adjust columns manually excluding `\(removeColumn)`
-- Steps:
-- 1) CREATE TABLE new_table (list columns except `\(removeColumn)`);
-- 2) INSERT INTO new_table (col1, col2, ...) SELECT col1, col2, ... FROM \(tableName);
-- 3) DROP TABLE \(tableName);
-- 4) ALTER TABLE new_table RENAME TO \(tableName);
-- 5) Recreate indices and foreign keys manually
"""
    }
}
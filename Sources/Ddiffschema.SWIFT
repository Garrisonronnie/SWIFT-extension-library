import Foundation

// MARK: - SchemaDiff
public struct SchemaDiff {
    public var tablesAdded: [Table] = []
    public var tablesRemoved: [Table] = []
    public var tablesChanged: [String] = []

    public var columnAdditions: [(table: String, column: Column)] = []
    public var columnRemovals: [(table: String, column: Column)] = []
    public var columnChanges: [(table: String, old: Column, new: Column)] = []

    public var indexAdditions: [(table: String, index: Index)] = []
    public var indexRemovals: [(table: String, index: Index)] = []

    public var foreignKeyAdditions: [(table: String, fk: ForeignKey)] = []
    public var foreignKeyRemovals: [(table: String, fk: ForeignKey)] = []

    public init() {}
    
    public var isEmpty: Bool {
        return tablesAdded.isEmpty &&
               tablesRemoved.isEmpty &&
               tablesChanged.isEmpty &&
               columnAdditions.isEmpty &&
               columnRemovals.isEmpty &&
               columnChanges.isEmpty &&
               indexAdditions.isEmpty &&
               indexRemovals.isEmpty &&
               foreignKeyAdditions.isEmpty &&
               foreignKeyRemovals.isEmpty
    }
}

// MARK: - DiffEngine
public final class DiffEngine {
    public init() {}

    public func diff(old: Schema, new: Schema) -> SchemaDiff {
        var d = SchemaDiff()

        let oldTables = old.tables
        let newTables = new.tables

        // Tables Added
        for (tName, t) in newTables where oldTables[tName] == nil {
            d.tablesAdded.append(t)
        }

        // Tables Removed
        for (tName, t) in oldTables where newTables[tName] == nil {
            d.tablesRemoved.append(t)
        }

        // Tables Present in Both → Compare deeper
        for (tName, newT) in newTables {
            guard let oldT = oldTables[tName] else { continue }
            
            // Columns
            compareColumns(oldTable: oldT, newTable: newT, tableName: tName, diff: &d)

            // Indexes
            compareIndexes(oldTable: oldT, newTable: newT, tableName: tName, diff: &d)

            // Foreign Keys
            compareForeignKeys(oldTable: oldT, newTable: newT, tableName: tName, diff: &d)
        }

        return d
    }

    // MARK: - Columns
    private func compareColumns(oldTable: Table, newTable: Table, tableName: String, diff: inout SchemaDiff) {
        let oldCols = oldTable.columnMap()
        let newCols = newTable.columnMap()

        // Added
        for (cName, c) in newCols where oldCols[cName] == nil {
            diff.columnAdditions.append((table: tableName, column: c))
        }

        // Changed
        for (cName, newC) in newCols {
            if let oldC = oldCols[cName],
               columnChanged(old: oldC, new: newC) {
                diff.columnChanges.append((table: tableName, old: oldC, new: newC))
            }
        }

        // Removed
        for (cName, c) in oldCols where newCols[cName] == nil {
            diff.columnRemovals.append((table: tableName, column: c))
        }
    }

    private func columnChanged(old: Column, new: Column) -> Bool {
        return old.type.lowercased() != new.type.lowercased()
            || old.isNotNull != new.isNotNull
            || old.isPrimaryKey != new.isPrimaryKey
            || old.defaultValue != new.defaultValue
    }

    // MARK: - Indexes
    private func compareIndexes(oldTable: Table, newTable: Table, tableName: String, diff: inout SchemaDiff) {
        let oldSet = Set(oldTable.indexes)
        let newSet = Set(newTable.indexes)

        for idx in newSet.subtracting(oldSet) {
            diff.indexAdditions.append((table: tableName, index: idx))
        }
        for idx in oldSet.subtracting(newSet) {
            diff.indexRemovals.append((table: tableName, index: idx))
        }
    }

    // MARK: - Foreign Keys
    private func compareForeignKeys(oldTable: Table, newTable: Table, tableName: String, diff: inout SchemaDiff) {
        let oldSet = Set(oldTable.foreignKeys)
        let newSet = Set(newTable.foreignKeys)

        for fk in newSet.subtracting(oldSet) {
            diff.foreignKeyAdditions.append((table: tableName, fk: fk))
        }
        for fk in oldSet.subtracting(newSet) {
            diff.foreignKeyRemovals.append((table: tableName, fk: fk))
        }
    }
}

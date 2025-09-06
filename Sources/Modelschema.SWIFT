import Foundation

// MARK: - Column
public struct Column: Equatable, Hashable, Codable {
    public var name: String
    public var type: String
    public var isPrimaryKey: Bool
    public var isNotNull: Bool
    public var defaultValue: String?

    public init(
        name: String,
        type: String,
        isPrimaryKey: Bool = false,
        isNotNull: Bool = false,
        defaultValue: String? = nil
    ) {
        self.name = name
        self.type = type
        self.isPrimaryKey = isPrimaryKey
        self.isNotNull = isNotNull
        self.defaultValue = defaultValue
    }
}

// MARK: - Index
public struct Index: Equatable, Hashable, Codable {
    public var name: String
    public var columns: [String]
    public var isUnique: Bool

    public init(name: String, columns: [String], isUnique: Bool = false) {
        self.name = name
        self.columns = columns
        self.isUnique = isUnique
    }
}

// MARK: - Foreign Key
public struct ForeignKey: Equatable, Hashable, Codable {
    public var name: String
    public var column: String
    public var refTable: String
    public var refColumn: String

    public init(name: String, column: String, refTable: String, refColumn: String) {
        self.name = name
        self.column = column
        self.refTable = refTable
        self.refColumn = refColumn
    }
}

// MARK: - Table
public struct Table: Equatable, Codable {
    public var name: String
    public var columns: [Column]
    public var indexes: [Index]
    public var foreignKeys: [ForeignKey]

    public init(
        name: String,
        columns: [Column],
        indexes: [Index] = [],
        foreignKeys: [ForeignKey] = []
    ) {
        self.name = name
        self.columns = columns
        self.indexes = indexes
        self.foreignKeys = foreignKeys
    }

    public func columnMap() -> [String: Column] {
        Dictionary(uniqueKeysWithValues: columns.map { ($0.name.lowercased(), $0) })
    }
}

// MARK: - Schema
public struct Schema: Codable {
    public var tables: [String: Table]

    public init(tables: [String: Table] = [:]) {
        self.tables = tables
    }

    public func table(named: String) -> Table? {
        tables[named.lowercased()]
    }
}

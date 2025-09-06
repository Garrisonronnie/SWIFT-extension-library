# DDiffExtensions

DDiffExtensions is a **Swift-based database schema diff and migration tool** for SQLite, PostgreSQL, and MySQL. It can:

- Compare two SQL schemas (`diff` command)
- Generate migration SQL (`migrate`)
- Rollback changes (`rollback`)
- Test migrations safely (`test-migrate`)
- Visualize schema differences (`visualize`)

This project is designed for developers who want **safe, automated schema evolution** for their applications.

---

## Features

- **Schema Diffing**: Identify added, removed, or modified tables and columns.
- **Migration Generation**: Generate forward migration SQL with support for dialects.
- **Rollback Generation**: Safely revert migrations or specific table changes.
- **Test Migration**: Run migrations on an in-memory SQLite database before production.
- **Visualization**: Generate ASCII or Graphviz DOT representations of schema differences.
- **Foreign Keys and Index Support**: Includes optional handling for foreign keys and indexes.
- **Extensible**: Fully Swift-based, easy to extend for custom dialects or rules.

---

## Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/DDiffExtensions.git
cd DDiffExtensions
How to use and examples 

swift build -c release

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT
);

CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    email TEXT UNIQUE,
    bio TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

ddiff diff old.sql new.sql

---
# Compare two schema files
ddiff diff old.sql new.sql

# Generate migration SQL
ddiff migrate old.sql new.sql [--dry-run] [--dialect sqlite|postgres|mysql]

# Rollback a migration
ddiff rollback old.sql new.sql [--table tableName] [--dialect sqlite|postgres|mysql]

# Test migration in-memory (SQLite only)
ddiff test-migrate old.sql new.sql

# Visualize schema differences
ddiff visualize old.sql new.sql [--format dot|ascii]

### **`.gitignore`**

```gitignore
# Swift / Xcode
.build/
DerivedData/
*.xcworkspace
*.xcodeproj/project.xcworkspace
*.xcodeproj/xcuserdata/

# Swift Package Manager
Packages/
.swiftpm/
.build/

# macOS
.DS_Store

# Logs
*.log

# SQLite databases
*.sqlite
*.sqlite3

# Command-line artifacts
*.swiftdoc
*.swiftdb








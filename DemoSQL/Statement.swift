//
//  Statement.swift
//

import Foundation
import sqlite3

// These objects are NOT thread-safe! You must only use a statement or cursor on
// the same thread as the database which created it.

public final class Statement: Sequence {
    // MARK: Private variables
    
    fileprivate var statementHandle: OpaquePointer
    fileprivate let parentDatabase: Database
    
    private lazy var bindParameterCount: Int = { [unowned self] in Int(sqlite3_bind_parameter_count(self.statementHandle)) }()

    // MARK: Public variables
    
    public lazy var columnCount: Int = { [unowned self] in Int(sqlite3_column_count(self.statementHandle)) }()
    
    public lazy var columnNames: [String] = { [unowned self] in
        var names = [String]()
        for idx in 0..<self.columnCount {
            let namePtr = sqlite3_column_name(self.statementHandle, Int32(idx))
            names.append(String(cString: namePtr!)) // can only be null in an out-of-memory scenario
        }
        return names
        }()
    
    // MARK: Lifecycle
    
    internal init(handle: OpaquePointer, parent: Database) {
        statementHandle = handle
        parentDatabase = parent
    }
    
    deinit {
        sqlite3_finalize(statementHandle)
    }
    
    // MARK: Iterating
    
    public func makeIterator() -> Cursor {
        reset()
        return Cursor(self)
    }
    
    public func run() {
        let _ = self.map { _ in return Swift.Void }
    }
    
    // MARK: Binding values
    
    public func clearBindings() {
        reset()
        sqlite3_clear_bindings(statementHandle)
    }
    
    public func bind(_ values: DatabaseBindable...) {
        precondition(values.count <= bindParameterCount)
        
        clearBindings()
        
        for (idx, v) in values.enumerated() {
            v.bind(to: self, at: idx)
        }
    }
    
    public func bind(_ value: DatabaseBindable?, at idx: Int) {
        if let value = value {
            value.bind(to: self, at: idx)
        }
        else {
            bindNull(at: idx)
        }
    }
    
    public func bindNull(at idx: Int) {
        precondition(idx >= 0)
        precondition(idx < bindParameterCount)
        
        let statusCode = sqlite3_bind_null(statementHandle, formSQLiteBindIndex(idx))
        assert(statusCode == SQLITE_OK, "Bad return from bind (message: \(parentDatabase.errorMessage)")
    }
    
    public func bindInt64(_ value: Int64, at idx: Int) {
        precondition(idx >= 0)
        precondition(idx < bindParameterCount)
        
        let statusCode = sqlite3_bind_int64(statementHandle, formSQLiteBindIndex(idx), value)
        assert(statusCode == SQLITE_OK, "Bad return from bind (message: \(parentDatabase.errorMessage)")
    }
    
    public func bindDouble(_ value: Double, at idx: Int) {
        precondition(idx >= 0)
        precondition(idx < bindParameterCount)
        
        let statusCode = sqlite3_bind_double(statementHandle, formSQLiteBindIndex(idx), value)
        assert(statusCode == SQLITE_OK, "Bad return from bind (message: \(parentDatabase.errorMessage)")
    }
    
    public func bindString(_ value: String, at idx: Int) {
        precondition(idx >= 0)
        precondition(idx < bindParameterCount)
        
        let statusCode = sqlite3_bind_text(statementHandle, formSQLiteBindIndex(idx), value, -1, SQLITE_TRANSIENT)
        assert(statusCode == SQLITE_OK, "Bad return from bind (message: \(parentDatabase.errorMessage)")
    }
    
    public func bindData(_ value: Data, at idx: Int) {
        precondition(idx >= 0)
        precondition(idx < bindParameterCount)
        
        value.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
            let statusCode = sqlite3_bind_blob(statementHandle, formSQLiteBindIndex(idx), bytes, Int32(value.count), SQLITE_TRANSIENT)
            assert(statusCode == SQLITE_OK, "Bad return from bind (message: \(parentDatabase.errorMessage)")
        }
    }
    
    public func bindInt<T: SignedInteger>(_ value: T, at idx: Int) {
        bindInt64(value.toIntMax(), at: idx)
    }
    
    public func bindUInt<T: UnsignedInteger>(_ value: T, at idx: Int) {
        bindInt64(value.toIntMax(), at: idx)
    }
    
    // MARK: Private methods
    
    private func reset() {
        sqlite3_reset(statementHandle)
    }
    
    // SQLite uses 1-based indices for binding values.
    private func formSQLiteBindIndex(_ idx: Int) -> Int32 {
        return Int32(idx + 1)
    }
}

public struct Cursor: IteratorProtocol {
    // MARK: Private variables
    
    private let statement: Statement
    
    // MARK: Initializers
    
    fileprivate init(_ statement: Statement) {
        self.statement = statement
    }
    
    // MARK: IteratorProtocol
    
    public func next() -> Cursor? {
        let statusCode = sqlite3_step(statement.statementHandle)
        switch statusCode {
        case SQLITE_DONE:
            return nil
        case SQLITE_ROW:
            return self
        default:
            assertionFailure("Error iterating cursor: \(statement.parentDatabase.errorMessage)")
            return nil
        }
    }
    
    // MARK: Accessing column values
    
    public subscript(_ idx: Int) -> Double {
        precondition(idx >= 0)
        precondition(idx < statement.columnCount)
        
        return sqlite3_column_double(statement.statementHandle, Int32(idx))
    }
    
    public subscript(_ idx: Int) -> Float {
        return Float(self[idx] as Double)
    }
    
    public subscript(_ idx: Int) -> Data? {
        precondition(idx >= 0)
        precondition(idx < statement.columnCount)
        
        guard let dataPointer = sqlite3_column_blob(statement.statementHandle, Int32(idx)) else {
            return nil
        }
        let byteCount = sqlite3_column_bytes(statement.statementHandle, Int32(idx))
        
        let buffer = UnsafeRawBufferPointer(start: dataPointer, count: Int(byteCount))
        
        return Data(buffer)
    }
    
    public subscript(_ idx: Int) -> String? {
        precondition(idx >= 0)
        precondition(idx < statement.columnCount)
        
        guard let stringPointer = sqlite3_column_text(statement.statementHandle, Int32(idx)) else {
            return nil
        }
        return String(cString: stringPointer)
    }
    
    public subscript(_ idx: Int) -> Int64 {
        precondition(idx >= 0)
        precondition(idx < statement.columnCount)
        
        return sqlite3_column_int64(statement.statementHandle, Int32(idx))
    }
    
    public subscript(_ idx: Int) -> Int {
        return Int(self[idx] as Int64)
    }
    
    public subscript(_ idx: Int) -> UInt {
        return UInt(self[idx] as Int64)
    }
    
    public subscript(_ idx: Int) -> Date? {
        precondition(idx >= 0)
        precondition(idx < statement.columnCount)
        
        guard !isColumnNull(idx) else {
            return nil
        }
        
        return Date(timeIntervalSince1970: self[idx])
    }
    
    // MARK: Private methods
    
    private func isColumnNull(_ idx: Int) -> Bool {
        return sqlite3_column_type(statement.statementHandle, Int32(idx)) == SQLITE_NULL
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: (@convention(c) (UnsafeMutableRawPointer?) -> Void).self)

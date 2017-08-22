//
//  Database.swift
//

import Foundation
import sqlite3

// These objects are NOT thread-safe! You must only use a database from the
// thread on which it was created.

public final class Database {
    private let dbHandle: OpaquePointer
    public let databaseURL: URL
    
    public convenience init() throws {
        try self.init(databaseURL: URL(string: ":memory:")!)
    }
    
    public init(databaseURL: URL) throws {
        self.databaseURL = databaseURL
        
        var tempHandle: OpaquePointer? = nil
        let statusCode = sqlite3_open_v2(databaseURL.absoluteString, &tempHandle, (SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_URI), nil)
        
        guard statusCode == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(tempHandle))
            sqlite3_close(tempHandle)
            throw DatabaseError(code: statusCode, message: message)
        }
        
        dbHandle = tempHandle!
    }
    
    deinit {
        sqlite3_close_v2(dbHandle)
    }
    
    public func prepare(_ sqlStatement: String) throws -> Statement {
        var statementHandle: OpaquePointer? = nil
        let statusCode = sqlStatement.utf8CString.withUnsafeBufferPointer { (ptr) -> Int32 in
            return sqlite3_prepare_v2(dbHandle, ptr.baseAddress, Int32(ptr.count), &statementHandle, nil)
        }
        
        guard let preparedHandle = statementHandle else {
            switch statusCode {
            case SQLITE_OK:
                throw DatabaseError(code: SQLITE_MISUSE, message: "Empty query or comment")
            default:
                throw DatabaseError(code: statusCode, message: self.errorMessage)
            }
        }
        
        // Handle must be wrapped in a statement to ensure it is freed
        // (transfer ownership to ARC object)
        let statement = Statement(handle: preparedHandle, parent: self)
        if statusCode == SQLITE_OK {
            return statement
        }
        else {
            throw DatabaseError(code: statusCode, message: self.errorMessage)
        }
    }
    
    public func exec(_ sqlStatements: String, rowCallback: (([String : String]) -> Bool)? = nil) throws {
        // C function pointer passed as callback to sqlite3_exec
        let cRowCallback: (@convention(c) (UnsafeMutableRawPointer?, Int32, UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?, UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32)?
        
        // Object wrapping "captured" variables i.e. Swift row callback
        let context: ExecContext? // must not be freed until after sqlite3_exec finishes
        
        // Opaque pointer to context object passed to sqlite3_exec
        let cContext: UnsafeMutableRawPointer?

        if let swiftCallback = rowCallback {
            cRowCallback = { (contextPtr: UnsafeMutableRawPointer!, columnCount: Int32, columnValues: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>!, columnNames: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>!) -> Int32 in
                // Wrap C arrays of C strings to take advantage of Collection methods
                let columnNamesBuffer = UnsafeBufferPointer(start: columnNames, count: Int(columnCount))
                let columnValuesBuffer = UnsafeBufferPointer(start: columnValues, count: Int(columnCount))
                
                // Prepare dictionary to hold column names/values
                var results = [String : String](minimumCapacity: Int(columnCount))
                
                // Iterate through the C string pointers in pairs
                for (name, value) in zip(columnNamesBuffer, columnValuesBuffer) {
                    // Add an entry to the results dictionary for each non-null value C string pointer
                    if let value = value {
                        let nameString = String(cString: name!)
                        let valueString = String(cString: value)
                        results[nameString] = valueString
                    }
                }
                
                // Convert borrowed pointer back to ExecContext object (does not change reference count)
                let contextObj: ExecContext = Unmanaged.fromOpaque(contextPtr).takeUnretainedValue()
                
                if contextObj.callback(results) {
                    return 0 // continue executing the query
                }
                else {
                    return 1 // cancel the query and stop
                }
            }
            
            // Wrap up "captured" variables in AnyObject
            context = ExecContext(swiftCallback)
            
            // Get a borrowed pointer to context (does not change reference count)
            cContext = Unmanaged.passUnretained(context!).toOpaque()
        }
        else {
            cRowCallback = nil
            context = nil
            cContext = nil
        }
        
        // Inout parameter to capture detailed error message
        var errmsg: UnsafeMutablePointer<CChar>? = nil
        
        let code = sqlite3_exec(dbHandle, sqlStatements, cRowCallback, cContext, &errmsg)
        
        let errorString: String?
        if let realMsg = errmsg {
            // SQLite documentation states we own the error message. Copy its contents and free it.
            errorString = String(cString: realMsg)
            sqlite3_free(realMsg)
        }
        else {
            errorString = nil
        }
        
        guard code == SQLITE_OK else {
            throw DatabaseError(code: code, message: errorString)
        }
    }
    
    // MARK: Internal
    
    // Returns a String describing the most recent error.
    internal var errorMessage: String {
        return String(cString: sqlite3_errmsg(dbHandle))
    }
    
    // MARK: Private
    
    // Needed because the Swift closure must be wrapped in an object to pass through Unmanaged as a param to the C func.
    private final class ExecContext {
        let callback: ([String : String]) -> Bool
        
        init(_ callback: @escaping ([String : String]) -> Bool) {
            self.callback = callback
        }
    }
}

public struct DatabaseError: Error {
    public let code: Int32
    public let message: String
    
    internal init(code: Int32, message: String? = nil) {
        self.code = code
        self.message = message ?? String(cString: sqlite3_errstr(code))
    }
}

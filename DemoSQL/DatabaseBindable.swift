//
//  DatabaseBindable.swift
//

import Foundation

public protocol DatabaseBindable {
    func bind(to statement: Statement, at idx: Int)
}

extension String: DatabaseBindable {
    public func bind(to statement: Statement, at idx: Int) {
        statement.bindString(self, at: idx)
    }
}

extension Data: DatabaseBindable {
    public func bind(to statement: Statement, at idx: Int) {
        statement.bindData(self, at: idx)
    }
}

extension Double: DatabaseBindable {
    public func bind(to statement: Statement, at idx: Int) {
        statement.bindDouble(self, at: idx)
    }
}

extension Float: DatabaseBindable {
    public func bind(to statement: Statement, at idx: Int) {
        statement.bindDouble(Double(self), at: idx)
    }
}

extension Int: DatabaseBindable {
    public func bind(to statement: Statement, at idx: Int) {
        statement.bindInt(self, at: idx)
    }
}

extension Int8: DatabaseBindable {
    public func bind(to statement: Statement, at idx: Int) {
        statement.bindInt(self, at: idx)
    }
}

extension Int16: DatabaseBindable {
    public func bind(to statement: Statement, at idx: Int) {
        statement.bindInt(self, at: idx)
    }
}

extension Int32: DatabaseBindable {
    public func bind(to statement: Statement, at idx: Int) {
        statement.bindInt(self, at: idx)
    }
}

extension Int64: DatabaseBindable {
    public func bind(to statement: Statement, at idx: Int) {
        statement.bindInt(self, at: idx)
    }
}

extension UInt: DatabaseBindable {
    public func bind(to statement: Statement, at idx: Int) {
        statement.bindUInt(self, at: idx)
    }
}

extension UInt8: DatabaseBindable {
    public func bind(to statement: Statement, at idx: Int) {
        statement.bindUInt(self, at: idx)
    }
}

extension UInt16: DatabaseBindable {
    public func bind(to statement: Statement, at idx: Int) {
        statement.bindUInt(self, at: idx)
    }
}

extension UInt32: DatabaseBindable {
    public  func bind(to statement: Statement, at idx: Int) {
        statement.bindUInt(self, at: idx)
    }
}

extension UInt64: DatabaseBindable {
    public func bind(to statement: Statement, at idx: Int) {
        statement.bindUInt(self, at: idx)
    }
}

extension Date: DatabaseBindable {
    public func bind(to statement: Statement, at idx: Int) {
        statement.bindDouble(self.timeIntervalSince1970, at: idx)
    }
}

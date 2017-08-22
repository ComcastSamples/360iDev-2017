//
//  DemoSQL_macOS_FrameworkTests.swift
//

import XCTest
@testable import DemoSQL

class DemoSQL_macOS_FrameworkTests: XCTestCase {
    
    
    var database: Database!
    
    override func setUp() {
        super.setUp()
        database = try! Database()
    }
    
    override func tearDown() {
        database = nil
        super.tearDown()
    }
    
    func testWrite() {
        do {
            try database.exec(schema)
            
            try insertPeople()
            
            let select = try database.prepare("SELECT COUNT(*) FROM people")
            
            let results: [Int] = select.map { cursor in cursor[0] as Int }
            
            XCTAssertEqual(results.count, 1, "Should return one row")
            XCTAssertEqual(results.first, 3, "Should return count of 3")
        }
        catch {
            XCTFail("unexpected error: \(error)")
        }
    }
    
    func testGetAverageHeight() {
        do {
            try database.exec(schema)
            
            try insertPeople()
            
            let select = try database.prepare("SELECT avg(height) FROM people")
            
            let results: [Double] = select.map { cursor in cursor[0] as Double }
            
            XCTAssertEqual(results.count, 1, "Should return one row")
            
            if let avg = results.first {
                XCTAssertGreaterThan(avg, 163.0, "Average should be bigger than the smallest number")
                XCTAssertLessThan(avg, 193.0, "Average should be smaller than the biggest number")
            }
        }
        catch {
            XCTFail("unexpected error: \(error)")
        }
    }
    
    func testExec() {
        do {
            try database.exec(schema)
            
            try insertPeople()
            
            var roles = [String: String]()
            try database.exec("SELECT firstName, role FROM people;") { row in
                let name = row["firstName"]!
                let role = row["role"]!
                roles[name] = role
                print("Name: \(name), role: \(role)")
                return true
            }
            
            XCTAssertEqual(roles.count, 3)
        }
        catch {
            XCTFail("unexpected error: \(error)")
        }
    }
    
    func insertPeople() throws {
        let insert = try database.prepare("INSERT INTO people VALUES (?, ?, ?, ?)")
        
        insert.bind("Andrew", "Morrow", "Speaker", 193)
        insert.run()
        
        insert.bind("Michael", "Morrow", "Attendee", 178)
        insert.run()
        
        insert.bind("Conrad", "Stoll", "Speaker", 195)
        insert.run()
    }
}

let schema = "CREATE TABLE people ( firstName TEXT, familyNames TEXT, role TEXT, height INTEGER );"
let weather_schema = "CREATE TABLE measurement ( value DOUBLE );"

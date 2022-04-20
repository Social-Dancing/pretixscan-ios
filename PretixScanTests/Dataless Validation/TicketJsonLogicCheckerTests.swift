//
//  TicketJsonLogicCheckerTests.swift
//  PretixScanTests
//
//  Created by Konstantin Kostov on 11/04/2022.
//  Copyright © 2022 rami.io. All rights reserved.
//

import XCTest
import SwiftyJSON
@testable import pretixSCAN

class TicketJsonLogicCheckerTests: XCTestCase {
    private let jsonDecoder = JSONDecoder.iso8601withFractionsDecoder
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ" // this should be the same as TicketJsonLogicChecker.dateFormatter.dateFormat
        return formatter
    }()
    
    private func getListWith(rules: JSON? = nil, list: String = "list2") -> CheckInList {
        let jsonData = testFileContents(list, "json")
        var exampleList = try! jsonDecoder.decode(CheckInList.self, from: jsonData)
        if let rules = rules {
            exampleList.rules = rules
        }
        return exampleList
    }
    
    func testListRulesCanBeSet() {
        let list = getListWith(rules: JSON(["foo": "bar"]))
        XCTAssertEqual(list.rules?.rawString(), "{\n  \"foo\" : \"bar\"\n}")
    }
    
    func testListRulesAreDecodedFromJSON() {
        let list = getListWith(rules: nil, list: "list2-rules")
        XCTAssertEqual(list.rules?.rawString(), "{\n  \"and\" : [\n    false,\n    true\n  ]\n}")
    }
    
    
    func testCheckerFailsSimpleRules() {
        let list = getListWith(rules: JSON(["and": [false, true]]))
        let sut = TicketJsonLogicChecker(list: list, event: mockEvent)
        
        let result = sut.redeem(ticket: mockTicket())
        
        switch result {
        case .success():
            XCTFail("Rules should be failing")
        case .failure(let err):
            XCTAssertEqual(err, .rules)
        }
    }
    
    func testCheckerValidatesSimpleRules() {
        let list = getListWith(rules: JSON(["and": [true, true]]))
        let sut = TicketJsonLogicChecker(list: list, event: mockEvent)
        
        let result = sut.redeem(ticket: mockTicket())
        switch result {
        case .success():
            break
        case .failure(let err):
            XCTFail("Expected success but failed with \(String(describing: err))")
        }
    }
    
    func testCheckerFailsRulesOnProduct() {
        let rules = """
{
  "inList": [
    { "var": "product" },
    { "objectList": [{ "lookup": ["product", "2", "Ticket"] }] }
  ]
}
"""
        let list = getListWith(rules: JSON(rules))
        let sut = TicketJsonLogicChecker(list: list, event: mockEvent)
        
        let result = sut.redeem(ticket: mockTicket())
        switch result {
        case .success():
            XCTFail("list2 has a product limit to producs with id 1 so the validation should fail since it requires product with id 2")
        case .failure(let err):
            XCTAssertEqual(err, .rules)
        }
    }
    
    func testCheckerValidatesRulesOnProduct() {
        let rules = """
{
  "inList": [
    { "var": "product" },
    { "objectList": [{ "lookup": ["product", "2", "Ticket"] }, { "lookup": ["product", "1", "Ticket"] }] }
  ]
}
"""
        let list = getListWith(rules: JSON(rules))
        let sut = TicketJsonLogicChecker(list: list, event: mockEvent)
        
        let result = sut.redeem(ticket: mockTicket())
        switch result {
        case .success():
            break
        case .failure(let err):
            XCTFail("Expected success but failed with \(String(describing: err))")
        }
    }
    
    func testCheckerFailsRulesOnVariation() {
        let rules = """
{
  "inList": [
    { "var": "variation" },
    { "objectList": [{ "lookup": ["variation", "3", "Ticket"] }] }
  ]
}
"""
        let list = getListWith(rules: JSON(rules))
        let sut = TicketJsonLogicChecker(list: list, event: mockEvent)
        
        let result = sut.redeem(ticket: mockTicket())
        switch result {
        case .success():
            XCTFail("variation limited to id 3 which is not present in mockticket with variation 2")
        case .failure(let err):
            XCTAssertEqual(err, .rules)
        }
    }
    
    func testCheckerValidatesRulesOnVariation() {
        let rules = """
{
  "inList": [
    { "var": "variation" },
    { "objectList": [{ "lookup": ["variation", "3", "Ticket"] }, { "lookup": ["variation", "2", "Ticket"] }] }
  ]
}
"""
        let list = getListWith(rules: JSON(rules))
        let sut = TicketJsonLogicChecker(list: list, event: mockEvent)
        
        let result = sut.redeem(ticket: mockTicket())
        switch result {
        case .success():
            break
        case .failure(let err):
            XCTFail("Expected success but failed with \(String(describing: err))")
        }
    }
    
    
    func testCheckerFailsRulesOnEntriesToday() {
        // arrange
        let rules = """
{ "<": [{ "var": "entries_today" }, 1] }
"""
        let list = getListWith(rules: JSON(rules))
        let ds = mockDataStore([
            // entry in the past
            .init(redemptionRequest: .init(date: Date.distantPast, ignoreUnpaid: false, nonce: "", type: "entry"), eventSlug: "", checkInListIdentifier: 0, secret: ""),
            // exit today
            .init(redemptionRequest: .init(date: Date(), ignoreUnpaid: false, nonce: "", type: "exit"), eventSlug: "", checkInListIdentifier: 0, secret: ""),
            // entry today
            .init(redemptionRequest: .init(date: Date(), ignoreUnpaid: false, nonce: "", type: "entry"), eventSlug: "", checkInListIdentifier: 0, secret: "")
        ])
        let sut = TicketJsonLogicChecker(list: list, dataStore: ds, event: mockEvent)
        
        // act
        let result = sut.redeem(ticket: mockTicket())
        switch result {
        case .success():
            XCTFail("number of entries for today < 1, this is the second checkin and should fail")
        case .failure(let err):
            XCTAssertEqual(err, .rules)
        }
    }
    
    func testCheckerValidatesRulesOnEntriesToday() {
        // arrange
        let rules = """
{ "<": [{ "var": "entries_today" }, 1] }
"""
        let list = getListWith(rules: JSON(rules))
        let ds = mockDataStore([
            // entry in the past
            .init(redemptionRequest: .init(date: Date.distantPast, ignoreUnpaid: false, nonce: "", type: "entry"), eventSlug: "", checkInListIdentifier: 0, secret: ""),
            // exit today
            .init(redemptionRequest: .init(date: Date(), ignoreUnpaid: false, nonce: "", type: "exit"), eventSlug: "", checkInListIdentifier: 0, secret: ""),
        ])
        let sut = TicketJsonLogicChecker(list: list, dataStore: ds, event: mockEvent)
        
        // act
        let result = sut.redeem(ticket: mockTicket())
        switch result {
        case .success():
            break
        case .failure(let err):
            XCTFail("Expected success but failed with \(String(describing: err))")
        }
    }
    
    
    func testCheckerFailsRulesOnEntriesNumber() {
        // arrange
        let rules = """
{ "<": [{ "var": "entries_number" }, 1] }
"""
        let list = getListWith(rules: JSON(rules))
        let ds = mockDataStore([
            // entry in the past
            .init(redemptionRequest: .init(date: Date.distantPast, ignoreUnpaid: false, nonce: "", type: "entry"), eventSlug: "", checkInListIdentifier: 0, secret: ""),
            // exit today
            .init(redemptionRequest: .init(date: Date(), ignoreUnpaid: false, nonce: "", type: "exit"), eventSlug: "", checkInListIdentifier: 0, secret: ""),
        ])
        let sut = TicketJsonLogicChecker(list: list, dataStore: ds, event: mockEvent)
        
        // act
        let result = sut.redeem(ticket: mockTicket())
        switch result {
        case .success():
            XCTFail("number of entries < 1, this is the second checkin and should fail")
        case .failure(let err):
            XCTAssertEqual(err, .rules)
        }
    }
    
    func testCheckerValidatesRulesOnEntriesNumber() {
        // arrange
        let rules = """
{ "<": [{ "var": "entries_number" }, 1] }
"""
        let list = getListWith(rules: JSON(rules))
        let ds = mockDataStore([])
        let sut = TicketJsonLogicChecker(list: list, dataStore: ds, event: mockEvent)
        
        // act
        let result = sut.redeem(ticket: mockTicket())
        switch result {
        case .success():
            break
        case .failure(let err):
            XCTFail("Expected success but failed with \(String(describing: err))")
        }
    }
    
    func testGetEntriesDaysCount() {
        let dates = [
            dateFormatter.date(from: "2022-03-19T07:18:00.000Z")!,
            dateFormatter.date(from: "2022-03-20T07:08:00.000Z")!,
            dateFormatter.date(from: "2022-04-19T07:13:00.000Z")!,
            dateFormatter.date(from: "2021-04-19T07:30:00.000Z")!,
        ]
        
        let checkIns: [QueuedRedemptionRequest] = dates.map({
            .init(redemptionRequest: .init(date: $0, ignoreUnpaid: false, nonce: "", type: "entry"), eventSlug: "", checkInListIdentifier: 0, secret: "")
        })
        
        let count = TicketJsonLogicChecker.getEntriesDaysCount(checkIns, calendar: Calendar.current)
        
        XCTAssertEqual(count, 4)
    }
    
    func testGetEntriesTodayCount() {
        let dates = [
            dateFormatter.date(from: "2022-03-19T07:28:00.000Z")!,
            dateFormatter.date(from: "2022-03-20T07:28:00.000Z")!,
            dateFormatter.date(from: "2022-04-19T07:28:00.000Z")!,
            dateFormatter.date(from: "2021-04-19T07:30:00.000Z")!,
        ]
        
        let checkIns: [QueuedRedemptionRequest] = dates.map({
            .init(redemptionRequest: .init(date: $0, ignoreUnpaid: false, nonce: "", type: "entry"), eventSlug: "", checkInListIdentifier: 0, secret: "")
        })
        
        let count = TicketJsonLogicChecker.getEntriesTodayCount(checkIns, calendar: Calendar.current, today: dateFormatter.date(from: "2022-04-19T16:00:00.000Z")!)
        
        XCTAssertEqual(count, 1)
    }
    
    func testCheckerFailsRulesOnEntriesDays() {
        // Ticket is valid unlimited times, but only on two arbitrary days
        let rules = """
{
  "or": [
    { ">": [{ "var": "entries_today" }, 0] },
    { "<": [{ "var": "entries_days" }, 2] }
  ]
}
"""
        let dates = [dateFormatter.date(from: "2022-03-19T07:28:00.000Z")!, dateFormatter.date(from: "2022-04-19T07:28:00.000Z")!]
        let now = dateFormatter.date(from: "2022-05-19T07:28:00.000Z")!
        
        let list = getListWith(rules: JSON(rules))
        let ds = mockDataStore([
            .init(redemptionRequest: .init(date: dates[0], ignoreUnpaid: false, nonce: "", type: "entry"), eventSlug: "", checkInListIdentifier: 0, secret: ""),
            .init(redemptionRequest: .init(date: dates[0], ignoreUnpaid: false, nonce: "", type: "exit"), eventSlug: "", checkInListIdentifier: 0, secret: ""),
            .init(redemptionRequest: .init(date: dates[1], ignoreUnpaid: false, nonce: "", type: "entry"), eventSlug: "", checkInListIdentifier: 0, secret: ""),
            .init(redemptionRequest: .init(date: dates[1], ignoreUnpaid: false, nonce: "", type: "exit"), eventSlug: "", checkInListIdentifier: 0, secret: ""),
        ])
        let sut = TicketJsonLogicChecker(list: list, dataStore: ds, event: mockEvent, date: now)
        
        // act
        let result = sut.redeem(ticket: mockTicket())
        switch result {
        case .success():
            XCTFail("attempted redeem on a 3rd day should fail")
        case .failure(let err):
            XCTAssertEqual(err, .rules)
        }
        
    }
    
    func testCheckerValidatesRulesOnEntriesDays() {
        // Ticket is valid unlimited times, but only on two arbitrary days
        let rules = """
{
  "or": [
    { ">": [{ "var": "entries_today" }, 0] },
    { "<": [{ "var": "entries_days" }, 2] }
  ]
}
"""
        let dates = [dateFormatter.date(from: "2022-03-19T07:28:00.000Z")!]
        let now = dateFormatter.date(from: "2022-05-19T07:28:00.000Z")!
        
        let list = getListWith(rules: JSON(rules))
        let ds = mockDataStore([
            .init(redemptionRequest: .init(date: dates[0], ignoreUnpaid: false, nonce: "", type: "entry"), eventSlug: "", checkInListIdentifier: 0, secret: ""),
            .init(redemptionRequest: .init(date: dates[0], ignoreUnpaid: false, nonce: "", type: "exit"), eventSlug: "", checkInListIdentifier: 0, secret: ""),
        ])
        let sut = TicketJsonLogicChecker(list: list, dataStore: ds, event: mockEvent, date: now)
        
        // act
        let result = sut.redeem(ticket: mockTicket())
        switch result {
        case .success():
            break
        case .failure(let err):
            XCTFail("Expected success but failed with \(String(describing: err))")
        }
        
    }
    
    func testCheckerFailsCheckinNotAfterAdmissionDate() {
        let rules = """
{ "isAfter": [{ "var": "now" }, { "buildTime": ["date_admission"] }, 10] }
"""
        let now = dateFormatter.date(from: "2020-01-01T08:45:00.000Z")!

        let list = getListWith(rules: JSON(rules))
        let ds = mockDataStore([])
        // mock event dateAdmission = 2020-01-01T09:00:00Z
        let sut = TicketJsonLogicChecker(list: list, dataStore: ds, event: mockEvent, date: now)

        switch sut.redeem(ticket: mockTicket()) {
        case .success():
            XCTFail("attempted redeem sooner than admission date")
        case .failure(let err):
            XCTAssertEqual(err, .rules)
        }
    }
    
    func testCheckerValidatesIsAfterTolerance() {
        let rules = """
{ "isAfter": [{ "var": "now" }, { "buildTime": ["date_admission"] }, 10] }
"""
        let now = dateFormatter.date(from: "2020-01-01T08:51:00.000Z")!

        let list = getListWith(rules: JSON(rules))
        let ds = mockDataStore([])
        // mock event dateAdmission = 2020-01-01T09:00:00Z
        let sut = TicketJsonLogicChecker(list: list, dataStore: ds, event: mockEvent, date: now)

        switch sut.redeem(ticket: mockTicket()) {
        case .success():
            break
        case .failure(let err):
            XCTFail("Expected success but failed with \(String(describing: err))")
        }
    }
    
    func testCheckerValidatesDateIsAfterTolerance() {
        let rules = """
{ "isAfter": [{ "var": "now" }, { "buildTime": ["date_admission"] }, 10] }
"""
        let now = dateFormatter.date(from: "2020-01-01T09:10:00.000Z")!

        let list = getListWith(rules: JSON(rules))
        let ds = mockDataStore([])
        // mock event dateAdmission = 2020-01-01T09:00:00Z
        let sut = TicketJsonLogicChecker(list: list, dataStore: ds, event: mockEvent, date: now)

        switch sut.redeem(ticket: mockTicket()) {
        case .success():
            break
        case .failure(let err):
            XCTFail("Expected success but failed with \(String(describing: err))")
        }
    }
    
    
    
    
    // MARK: - mocks
    var mockEvent: Event {
        let eventJsonData = testFileContents("event1", "json")
        return try! jsonDecoder.decode(Event.self, from: eventJsonData)
    }
    
    var mockItems: [Item] {
        ["item1", "item2"].map({item -> Item in
            let jsonData = testFileContents(item, "json")
            return try! jsonDecoder.decode(Item.self, from: jsonData)
        })
    }
    
    func mockDataStore(_ checkIns: [QueuedRedemptionRequest]) -> DatalessDataStore {
        return MockDataStore(keys: mockEvent.validKeys!.pems, revoked: [], questions: [], items: mockItems, checkIns: checkIns)
    }
    
    func mockTicket(_ item: Identifier = 1, variation: Identifier = 2, subEvent: Identifier = 4) -> TicketJsonLogicChecker.TicketData {
        TicketJsonLogicChecker.TicketData(secret: "1234", eventSlug: mockEvent.slug, item: item, variation: variation, subEvent: subEvent)
    }
    
    class MockDataStore: DatalessDataStore {
        private let keys: [String]
        private let revoked: [String]
        private let questions: [Question]
        private let items: [Item]
        private var checkIns: [QueuedRedemptionRequest]
        
        var stored: [Codable] = []
        
        init(keys: [String], revoked: [String], questions: [Question], items: [Item], checkIns: [QueuedRedemptionRequest]) {
            self.keys = keys
            self.revoked = revoked
            self.questions = questions
            self.items = items
            self.checkIns = checkIns
        }
        
        func getValidKeys(for event: Event) -> Result<[EventValidKey], Error> {
            .success(keys.map({EventValidKey(secret: $0)}))
        }
        
        func getRevokedKeys(for event: Event) -> Result<[RevokedSecret], Error> {
            .success(revoked.map({RevokedSecret(id: 0, secret: $0)}))
        }
        
        func getItem(by identifier: Identifier, in event: Event) -> Item? {
            return items.first(where: {$0.identifier == identifier})
        }
        
        func getQuestions(for item: Item, in event: Event) -> Result<[Question], Error> {
            return .success(questions)
        }
        
        func getQueuedCheckIns(_ secret: String, eventSlug: String) -> Result<[QueuedRedemptionRequest], Error> {
            return .success(checkIns)
        }
        
        func store<T>(_ resource: T, for event: Event) where T : Model {
            stored.append(resource)
            if let resp = resource as? QueuedRedemptionRequest {
                checkIns.append(resp)
            }
        }
    }
}

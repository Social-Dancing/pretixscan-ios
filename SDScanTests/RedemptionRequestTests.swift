//
//  RedemptionRequestTests.swift
//  PretixScanTests
//
//  Created by Daniel Jilg on 25.03.19.
//  Copyright © 2019 rami.io. All rights reserved.
//

import XCTest
@testable import pretixSCAN

class RedemptionRequestTests: XCTestCase {
    let jsonEncoder = JSONEncoder.iso8601withFractionsEncoder
    let jsonDecoder = JSONDecoder.iso8601withFractionsDecoder

    let exampleJSONNoQuestions = String("""
        {
          "force": false,
          "ignore_unpaid": false,
          "nonce": "Pvrk50vUzQd0DhdpNRL4I4OcXsvg70uA",
          "canceled_supported":true,
          "questions_supported": false,
          "type": "entry"
        }
    """.filter { !" \n\t\r".contains($0) }).data(using: .utf8)!

    let exampleJSON = """
        {
          "force": false,
          "ignore_unpaid": false,
          "nonce": "Pvrk50vUzQd0DhdpNRL4I4OcXsvg70uA",
          "datetime": null,
          "questions_supported": true,
          "type": "entry",
          "answers": {
            "4": "XS"
          }
        }
    """.data(using: .utf8)!

    var exampleObjectNoQuestions: RedemptionRequest?
    var exampleObject: RedemptionRequest?

    override func setUp() {
        exampleObjectNoQuestions = RedemptionRequest(
            date: nil,
            ignoreUnpaid: false,
            nonce: "Pvrk50vUzQd0DhdpNRL4I4OcXsvg70uA", type: "entry"
        )
        exampleObjectNoQuestions?.force = false
        exampleObjectNoQuestions?.questionsSupported = false

        exampleObject = RedemptionRequest(
            date: nil,
            ignoreUnpaid: false,
            nonce: "Pvrk50vUzQd0DhdpNRL4I4OcXsvg70uA", type: "entry"
        )
        exampleObject?.force = false
        exampleObject?.questionsSupported = true
    }

    func testParsingExampleNoQuestions() {
        XCTAssertNoThrow(try jsonDecoder.decode(RedemptionRequest.self, from: exampleJSONNoQuestions))
        let parsedInstance = try? jsonDecoder.decode(RedemptionRequest.self, from: exampleJSONNoQuestions)
        XCTAssertEqual(parsedInstance, exampleObjectNoQuestions)
    }

    func testEncodingExampleNoQuestions() {
        XCTAssertNoThrow(try jsonEncoder.encode(exampleObjectNoQuestions))
        let encodedInstance = try? jsonEncoder.encode(exampleObjectNoQuestions)
        XCTAssertNotNil(encodedInstance)
        let decoded = try! jsonDecoder.decode(RedemptionRequest.self, from: encodedInstance!)
        XCTAssertEqual(exampleObjectNoQuestions, decoded)
    }
}

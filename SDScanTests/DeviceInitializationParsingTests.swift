//
//  DeviceInitializationParsingTests.swift
//  PretixScanTests
//
//  Created by Daniel Jilg on 14.03.19.
//  Copyright © 2019 rami.io. All rights reserved.
//

import XCTest
@testable import pretixSCAN

class DeviceInitializationParsingTests: XCTestCase {
    let validDeviceInitializationRequest = DeviceInitializationRequest(
        token: "kpp4jn8g2ynzonp6",
        hardwareBrand: "Samsung",
        hardwareModel: "Galaxy S",
        softwareBrand: "pretixdroid",
        softwareVersion: "4.0.0"
    )

    let validDeviceInitializationResponse = DeviceInitializationResponse(
        organizer: "foo",
        deviceID: 5,
        uniqueSerial: "HHZ9LW9JWP390VFZ",
        apiToken: "1kcsh572fonm3hawalrncam4l1gktr2rzx25a22l8g9hx108o9oi0rztpcvwnfnd",
        name: "Bar"
    )

    let validRequestJSON = """
            {
                "token": "kpp4jn8g2ynzonp6",
                "hardware_brand": "Samsung",
                "hardware_model": "Galaxy S",
                "software_brand": "pretixdroid",
                "software_version": "4.0.0"
            }
            """.data(using: .utf8)!

    let validResponseJSON = """
            {
                "organizer": "foo",
                "device_id": 5,
                "unique_serial": "HHZ9LW9JWP390VFZ",
                "api_token": "1kcsh572fonm3hawalrncam4l1gktr2rzx25a22l8g9hx108o9oi0rztpcvwnfnd",
                "name": "Bar"
            }
            """.data(using: .utf8)!
    
    let validResponseWithSecurityProfileJSON = """
            {
                "organizer": "iosdemo",
                "device_id": 154,
                "unique_serial": "7SAYNAUWZYG1SB3T",
                "api_token": "a token",
                "name": "A device",
                "security_profile": "pretixscan_online_noorders",
                "gate": null
            }
            """.data(using: .utf8)!
    
    private let jsonDecoder = JSONDecoder.iso8601withFractionsDecoder

    func testDecodingValidRequest() {
        let parsedRequest = try? jsonDecoder.decode(DeviceInitializationRequest.self, from: validRequestJSON)
        XCTAssertNotNil(parsedRequest)
        XCTAssertEqual(parsedRequest, validDeviceInitializationRequest)
    }

    func testDecodingValidResponse() {
        let parsedResponse = try? jsonDecoder.decode(DeviceInitializationResponse.self, from: validResponseJSON)
        XCTAssertNotNil(parsedResponse)
        XCTAssertEqual(parsedResponse, validDeviceInitializationResponse)
    }
    
    func testDecodingResponseWithSecurityProfile() {
        let expectedResponse = DeviceInitializationResponse(organizer: "iosdemo", deviceID: 154, uniqueSerial: "7SAYNAUWZYG1SB3T", apiToken: "a token", name: "A device", securityProfile: "pretixscan_online_noorders")
        let parsedResponse = try? jsonDecoder.decode(DeviceInitializationResponse.self, from: validResponseWithSecurityProfileJSON)
        XCTAssertNotNil(parsedResponse)
        XCTAssertEqual(parsedResponse, expectedResponse)
    }
}

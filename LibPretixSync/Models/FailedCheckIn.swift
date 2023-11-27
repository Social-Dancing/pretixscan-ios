//
//  FailedCheckIn.swift
//  pretixSCAN
//
//  Created by Konstantin Kostov on 30/09/2021.
//  Copyright © 2021 rami.io. All rights reserved.
//

import Foundation

struct FailedCheckInRequest: Codable {
    public let errorReason: String
    
    /// The raw barcode you scanned. Required.
    public let rawBarcode: String
    
    /// Date and time of the scan. Optional.
    public let dateTime: Date?
    
    /// Type of scan, defaults to "entry".
    public let scanType: String
    
    /// Internal ID of an order position you matched. Optional.
    public let position: Int?
    
    /// Internal ID of an item you matched.
    public let rawItem: Int?
    
    /// Internal ID of an item variation you matched.
    public let rawVariation: Int?
    
    /// Internal ID of an event series date you matched.
    public let rawSubEvent: Int?
    
    private enum CodingKeys: String, CodingKey {
        case errorReason = "error_reason"
        case rawBarcode = "raw_barcode"
        case dateTime = "datetime"
        case scanType = "type"
        case position
        case rawItem = "raw_item"
        case rawVariation = "raw_variation"
        case rawSubEvent = "raw_subevent"
    }
}

extension FailedCheckInRequest {
    init(_ failedChecked: FailedCheckIn) {
        errorReason = failedChecked.errorReason
        rawBarcode = failedChecked.rawBarcode
        dateTime = failedChecked.dateTime
        scanType = failedChecked.scanType
        position = failedChecked.position
        rawItem = failedChecked.rawItem
        rawVariation = failedChecked.rawVariation
        rawSubEvent = failedChecked.rawSubEvent
    }
}

public struct FailedCheckIn: Model {
    public static var humanReadableName = "Failed Check-In"
    public static var stringName = "failed_checkins"
    
    /// The slug of the event this request belongs to
    public let eventSlug: String
    
    /// The identifier of the check-in-olist this request belongs to
    public let checkInListIdentifier: Identifier
    
    public let errorReason: String
    
    /// The raw barcode you scanned. Required.
    public let rawBarcode: String
    
    /// Date and time of the scan. Optional.
    public let dateTime: Date?
    
    /// Type of scan, defaults to "entry".
    public let scanType: String
    
    /// Internal ID of an order position you matched. Optional.
    public let position: Int?
    
    /// Internal ID of an item you matched.
    public let rawItem: Int?
    
    /// Internal ID of an item variation you matched.
    public let rawVariation: Int?
    
    /// Internal ID of an event series date you matched.
    public let rawSubEvent: Int?
}

extension FailedCheckIn {
    init?(response: RedemptionResponse?, error: Error?, _ slug: String, _ checkInListIdentifier: Identifier, _ checkInType: String, _ rawCode: String, _ event: Event) {
        
        if error != nil {
            self = FailedCheckIn(.error, slug, checkInListIdentifier, checkInType, rawCode, response, event: event)
            return nil
        }
        
        guard let response = response else {
            self = FailedCheckIn(.error, slug, checkInListIdentifier, checkInType, rawCode, nil, event: event)
            return nil
        }
        
        switch response.status {
        case .redeemed:
            // valid entry, no failed check-in
            break
        case .incomplete:
            // incomplete entries should not be logged
            return nil
        case .error:
            if let reason = response.errorReason {
                switch reason {
                case .unpaid:
                    self =  FailedCheckIn(.unpaid, slug, checkInListIdentifier, checkInType, rawCode, response, event: event)
                    return
                case .canceled:
                    self =  FailedCheckIn(.canceled, slug, checkInListIdentifier, checkInType, rawCode, response, event: event)
                    return
                case .alreadyRedeemed:
                    self =  FailedCheckIn(.alreadyRedeemed, slug, checkInListIdentifier, checkInType, rawCode, response, event: event)
                    return
                case .product:
                    self =  FailedCheckIn(.product, slug, checkInListIdentifier, checkInType, rawCode, response, event: event)
                    return
                case .rules:
                    self =  FailedCheckIn(.rules, slug, checkInListIdentifier, checkInType, rawCode, response, event: event)
                    return
                case .revoked:
                    self =  FailedCheckIn(.revoked, slug, checkInListIdentifier, checkInType, rawCode, response, event: event)
                    return
                case .invalid:
                    self =  FailedCheckIn(.invalid, slug, checkInListIdentifier, checkInType, rawCode, response, event: event)
                    return
                case .ambiguous:
                    self =  FailedCheckIn(.ambiguous, slug, checkInListIdentifier, checkInType, rawCode, response, event: event)
                    return
                case .blocked:
                    self =  FailedCheckIn(.blocked, slug, checkInListIdentifier, checkInType, rawCode, response, event: event)
                    return
                case .invalidTime:
                    self =  FailedCheckIn(.invalidTime, slug, checkInListIdentifier, checkInType, rawCode, response, event: event)
                    return
                case .unapproved:
                    self =  FailedCheckIn(.unapproved, slug, checkInListIdentifier, checkInType, rawCode, response, event: event)
                    return
                }
            } else {
                EventLogger.log(event: "FailedCheckIn with no error reason", category: .configuration, level: .warning, type: .info)
                self = FailedCheckIn(.error, slug, checkInListIdentifier, checkInType, rawCode, response, event: event)
                return
            }
        }
        
        return nil
    }
    
    init(_ reason: FailedCheckInErrorReason, _ slug: String, _ checkInListIdentifier: Identifier,  _ checkInType: String, _ rawCode: String, _ response: RedemptionResponse?, event: Event) {
        self = FailedCheckIn(eventSlug: slug, checkInListIdentifier: checkInListIdentifier, errorReason: reason.rawValue, rawBarcode: rawCode, dateTime: Date(), scanType: checkInType, position: response?.position?.identifier, rawItem: response?.position?.itemIdentifier, rawVariation: response?.position?.variation, rawSubEvent: response?.position?.subEvent)
    }
}

enum FailedCheckInErrorReason: String, Hashable, CaseIterable, Codable {
    case canceled
    case invalid
    case unpaid
    case product
    case rules
    case revoked
    case incomplete
    case alreadyRedeemed = "already_redeemed"
    case error
    case ambiguous
    case blocked
    case invalidTime = "invalid_time"
    case unapproved
}

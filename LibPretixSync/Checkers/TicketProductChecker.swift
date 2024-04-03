//
//  DatalessTicketValidator.swift
//  pretixSCAN
//
//  Created by Konstantin Kostov on 28/10/2021.
//  Copyright © 2021 rami.io. All rights reserved.
//

import Foundation

final class TicketProductChecker {
    private var checkInList: CheckInList
    weak var dataStore: DatalessDataStore?
    
    init(list: CheckInList, dataStore: DatalessDataStore) {
        self.checkInList = list
        self.dataStore = dataStore
    }
    
    
    func redeem(ticket: SignedTicketData, event: Event) -> Result<Item, ValidationError> {
        // is the product part of the check-in list
        if !checkInList.allProducts {
            if let limitProducts = checkInList.limitProducts,
               !limitProducts.contains(ticket.item) {
                return .failure(.product(subEvent: ticket.subEvent))
            }
        }
        
        // is the subevent part of the check-in list
        if let subEventId = checkInList.subEvent, subEventId != ticket.subEvent {
            return .failure(.invalidProductSubEvent)
        }
        
        // does the ticket correspond to a known product
        guard let item = dataStore?.getItem(by: ticket.item, in: event) else {
            return .failure(.unknownItem(subEvent: ticket.subEvent))
        }
        
        return .success(item)
    }
    
    enum ValidationError: Error, Hashable, Equatable {
        /// The product of the ticket is not part of the check-in list
        case product(subEvent: Int)
        /// The subevent of the ticket is not part of the check-in list
        case invalidProductSubEvent
        /// The ticket item identifier is unknown
        case unknownItem(subEvent: Int)
    }
}

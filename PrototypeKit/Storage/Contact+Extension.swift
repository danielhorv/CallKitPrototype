//
//  Contact+Extension.swift
//  PrototypeKit
//
//  Created by Daniel Horvath on 03.05.20.
//  Copyright © 2020 Daniel Horvath. All rights reserved.
//

import Foundation
import CoreData

extension CDContact {
    
    var status: ContactStatus {
        guard let statusRaw = statusRaw, let status = ContactStatus(rawValue: statusRaw) else {
            fatalError("ContactStatus not found")
        }
        
        return status
    }
}

extension Address {
    init(cdAddress: CDAddress) {
        street = cdAddress.street
        city = cdAddress.city
        zipCode = cdAddress.zipCode
        country = cdAddress.country
    }
}

extension Contact {
    init(cdContact: CDContact) {
        id = cdContact.id ?? ""
        title = cdContact.title
        firstName = cdContact.firstName ?? ""
        lastName = cdContact.lastName ?? ""
        department = cdContact.department
        phoneNumber = cdContact.phoneNumber
        mobileNumber = cdContact.mobileNumber
        email = cdContact.email
        
        if let cdAddress = cdContact.address {
            address = Address(cdAddress: cdAddress)
        } else {
            address = nil
        }
        
        status = cdContact.status
    }
}


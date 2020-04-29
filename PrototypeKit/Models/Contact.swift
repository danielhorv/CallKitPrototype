//
//  Contact.swift
//  PrototypeKit
//
//  Created by Daniel Horvath on 29.04.20.
//  Copyright © 2020 Daniel Horvath. All rights reserved.
//

import Foundation

public struct Contact {
    public let id: String

    public let title: String?
    public let firstName: String
    public let lastName: String
    public let department: String?

    public let phoneNumber: String?
    public let mobileNumber: String?

    public let email: String?
    public let address: Address?

    public let status: ContactStatus
}

public struct Address: Codable, Equatable {
    public let street: String?
    public let city: String?
    public let zipCode: String?
    public let country: String?
    
    public init?(street: String?, city: String?, zipCode: String?, country: String?) {
        guard street != nil || city != nil || zipCode != nil || country != nil else { return nil }
        self.street = street
        self.city = city
        self.zipCode = zipCode
        self.country = country
    }
}

public enum ContactStatus: String, Decodable {
    case created
    case updated
    case deleted
}

public enum PhoneNumberType: CaseIterable {
    case phoneNumber
    case mobileNumber
}

extension Contact {
    public func phoneNumber(for type: PhoneNumberType) -> String? {
        switch type {
        case .phoneNumber:
            return phoneNumber
            
        case .mobileNumber:
            return mobileNumber
        }
    }
}

extension Contact: Decodable, Equatable {
    enum CodingKeys: String, CodingKey {
        case id = "objId"
        case title
        case firstName = "forename"
        case lastName = "surname"
        case department
        case phoneNumber
        case mobileNumber
        case ctiNumber
        case email = "mail"
        case address
        case status = "state"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        department = try container.decodeIfPresent(String.self, forKey: .department)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        mobileNumber = try container.decodeIfPresent(String.self, forKey: .mobileNumber)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        address = try container.decode(Address.self, forKey: .address)
        status = try {
            let rawValue = try container.decode(String.self, forKey: .status)
            return ContactStatus(rawValue: rawValue) ?? .created
        }()
    }
}

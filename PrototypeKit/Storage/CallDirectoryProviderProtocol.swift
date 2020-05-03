//
//  CallDirectoryProviderProtocol.swift
//  PrototypeKit
//
//  Created by Daniel Horvath on 03.05.20.
//  Copyright © 2020 Daniel Horvath. All rights reserved.
//

import Foundation


public enum CallDirectoryOperation: String {
    case loadAll
    case update
    case delete
}

public protocol CallDirectoryProviderProtocol {
    func loadUnsyncedContacts(for status: ContactStatus) throws -> [Contact]
    func markSynced(contact: Contact) throws
    func storeOrUpdate(contact: Contact) throws
    func delete(contact: Contact) throws
    var callDirectoryOperation: CallDirectoryOperation { get set }
}

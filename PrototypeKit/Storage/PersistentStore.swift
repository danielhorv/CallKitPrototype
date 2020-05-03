//
//  PersistentStore.swift
//  PrototypeKit
//
//  Created by Daniel Horvath on 03.05.20.
//  Copyright © 2020 Daniel Horvath. All rights reserved.
//

import UIKit

public protocol PersistentStore {
    var contacts: [Contact] { get }
    var numberOfContacts: Int { get }
    var numberOfUnsyncedContacts: Int { get }
    var numberOfUnsyncedCreatedContacts: Int { get }
    var numberOfUnsyncedUpdatedContacts: Int { get }
    var numberOfUnsyncedDeletedContacts: Int { get }
}

extension PersistentStore {
    public func percentage(for unsyncedContacts: Int) -> CGFloat {
        return  (1 - (CGFloat(numberOfUnsyncedContacts) / CGFloat(unsyncedContacts))) * 100
    }
}

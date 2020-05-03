//
//  Contacts+DataSource.swift
//  CallKitPrototype
//
//  Created by Daniel Horvath on 03.05.20.
//  Copyright © 2020 Daniel Horvath. All rights reserved.
//

import Foundation
import PrototypeKit
import RxSwift
import RxCocoa
import RxDataSources

struct ContactSectionModel {
    let header: String
    var items: [Contact]
}

extension Contact: IdentifiableType {
    public typealias Identity = String

    public var identity: String {
        return id
    }
}

extension ContactSectionModel: AnimatableSectionModelType {

    typealias Identity = String
    
    var identity: String {
        return header
    }
    
    init(original: ContactSectionModel, items: [Contact]) {
        self = original
        self.items = items
    }
}

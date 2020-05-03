//
//  ContactsReactor.swift
//  CallKitPrototype
//
//  Created by Daniel Horvath on 03.05.20.
//  Copyright © 2020 Daniel Horvath. All rights reserved.
//

import UIKit
import RxSwift
import ReactorKit
import PrototypeKit

class ContactsReactor: Reactor {
    
    enum Action {
        case stopSync
    }
    
    enum Mutation {
        case setContacts([Contact])
    }
    
    struct State {
        var contacts: [Contact] = []
    }
    
    private let contactsProvider: ContactsProviderProtocol
    private let callDirectorySyncController: CallDirectorySyncController
    let initialState = State()
    
    init(contactsProvider: ContactsProviderProtocol, callDirectorySyncController: CallDirectorySyncController) {
        self.contactsProvider = contactsProvider
        self.callDirectorySyncController = callDirectorySyncController
    }
    
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let contactObservable = contactsProvider.contacts
            .distinctUntilChanged()
            .map { Mutation.setContacts($0) }
        
        return .merge(mutation, contactObservable)
    }
    
    func mutate(action: ContactsReactor.Action) -> Observable<ContactsReactor.Mutation> {
        switch action {
        case .stopSync:
            callDirectorySyncController.stopSync()
            return .empty()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setContacts(let contacts):
            print("allContacts: ", contacts.count)
            newState.contacts = contacts
        }
        
        return newState
    }
}

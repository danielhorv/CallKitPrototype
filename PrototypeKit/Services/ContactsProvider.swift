//
//  ContactsProvider.swift
//  PrototypeKit
//
//  Created by Daniel Horvath on 29.04.20.
//  Copyright © 2020 Daniel Horvath. All rights reserved.
//

import Foundation
import RxSwift
import CoreData


public protocol ContactsProviderProtocol {
    var contacts: Observable<[Contact]> { get }
    var unsyncedContacts: Observable<Int> { get }
//    var callDirectoryUpdateAvailable: Observable<Bool> { get }
    func fetchContacts() -> Single<[Contact]>
}

public class MockContactsProvider: NSObject, ContactsProviderProtocol {
    public let unsyncedContactsSubject = BehaviorSubject<Int>(value: 0)
    
    public var unsyncedContacts: Observable<Int> {
        return unsyncedContactsSubject.asObservable()
    }
    
    private let coreDataStore: CoreDataStore

    private lazy var contactsSubject = BehaviorSubject<[Contact]>(value: coreDataStore.contacts)
    
    public var contacts: Observable<[Contact]> {
        return contactsSubject.asObservable()
    }
    
    public init(coreDataStore: CoreDataStore) {
        self.coreDataStore = coreDataStore
        
        super.init()
        
        if coreDataStore.contacts.isEmpty {
            initialFetchAndStore()
        }
        
//        try? coreDataStore.resetSyncState()

    }
    
    private func initialFetchAndStore() {
        _ = fetchContacts()
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] contacts in
                let withoutDuplicatedContacts = Array(Set(contacts))
                
                do {
                    try withoutDuplicatedContacts.forEach { try self?.coreDataStore.storeOrUpdate(contact: $0) }
                    self?.contactsSubject.onNext(self?.coreDataStore.contacts ?? [])
                } catch {
                    print(error)
                }
            })
    }
    
    public func fetchContacts() -> Single<[Contact]> {
        let bundle = Bundle(for: Self.self)

        let url = bundle.url(forResource: "generated_100000", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let contacts = try! JSONDecoder().decode([Contact].self, from: data)

        return .just(contacts)
        
//        let request = URLRequest(url: URL(string: "https://my.api.mockaroo.com/phonebook.json?key=1c0fae70")!)
//
//        return Single.create { single in
//            URLSession.shared.dataTask(with: request) { (data, _, error) in
//                if let error = error {
//                    single(.error(error))
//                } else if let data = data {
//                    single(.success((try? JSONDecoder().decode([Contact].self, from: data)) ?? []))
//                } else {
//                    single(.success([]))
//                }
//            }.resume()
//
//            return Disposables.create()
//        }
    }
}

private class BundleHelper {}

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
    var callDirectoryUpdateAvailable: Observable<Bool> { get }
    func fetchContacts() -> Single<[Contact]>
}

public class MockContactsProvider: ContactsProviderProtocol {
    public let unsyncedContactsSubject = BehaviorSubject<Int>(value: 0)
    
    public var unsyncedContacts: Observable<Int> {
        return unsyncedContactsSubject.asObservable()
    }
    
    private let coreDataStore: CoreDataStore

    private lazy var contactsSubject = BehaviorSubject<[Contact]>(value: coreDataStore.contacts)
    
    public var contacts: Observable<[Contact]> {
        return contactsSubject.asObservable()
    }
    
    private lazy var updateSubject = PublishSubject<Bool>()
    
    public var callDirectoryUpdateAvailable: Observable<Bool> {
        return contacts
            .distinctUntilChanged()
            .map { _ in true }
    }
    
    public init(coreDataStore: CoreDataStore) {
        self.coreDataStore = coreDataStore
        
        if coreDataStore.contacts.isEmpty {
            initialFetchAndStore()
        }

//        let answer = zip(coreDataStore.contacts, Array(Set(coreDataStore.contacts))).enumerated().filter() {
//            $1.0 == $1.1
//        }.map{$0.0}
//
//        print(answer)
//        try? coreDataStore.resetSyncState()
        
    }
    
    private func initialFetchAndStore() {
        _ = fetchContacts()
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] contacts in
                let removedDuplicated = Array(Set(contacts))
                do {
                    try removedDuplicated.forEach { try self?.coreDataStore.storeOrUpdate(contact: $0) }
                    self?.contactsSubject.onNext(self?.coreDataStore.contacts ?? [])
                    
//                    let unsyncedContacts = self?.coreDataStore.numberOfUnSyncedContacts ?? 0
//                    self?.unsyncedContactsSubject.onNext(unsyncedContacts)
                } catch {
                    print(error)
                }
            })
    }
    
    public func fetchContacts() -> Single<[Contact]> {
        let bundle = Bundle(for: BundleHelper.self)

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


extension Array where Element: Hashable {
    func differences(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}

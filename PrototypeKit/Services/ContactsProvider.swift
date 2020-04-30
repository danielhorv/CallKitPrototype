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
    var callDirectoryUpdateAvailable: Observable<Bool> { get }
    func fetchContacts() -> Single<[Contact]>
}

public class MockContactsProvider: ContactsProviderProtocol {
    
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
    
//        try? coreDataStore.resetSyncState()
        
    }
    
    private func initialFetchAndStore() {
        _ = fetchContacts()
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] contacts in
                do {
                    try contacts.forEach { try self?.coreDataStore.storeOrUpdate(contact: $0) }
                    self?.contactsSubject.onNext(self?.coreDataStore.contacts ?? [])
                } catch {
                    print(error)
                }
            })
    }
    
    public func fetchContacts() -> Single<[Contact]> {
        let bundle = Bundle(for: BundleHelper.self)

        let url = bundle.url(forResource: "generated_30000", withExtension: "json")!
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

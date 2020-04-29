//
//  ContactsProvider.swift
//  PrototypeKit
//
//  Created by Daniel Horvath on 29.04.20.
//  Copyright © 2020 Daniel Horvath. All rights reserved.
//

import Foundation
import RxSwift

public protocol ContactsProviderProtocol {
    func fetchContacts() -> Single<[Contact]>
}

public class MockContactsProvider: ContactsProviderProtocol {
    
    public init() {} 
    
    public func fetchContacts() -> Single<[Contact]> {

        let request = URLRequest(url: URL(string: "https://my.api.mockaroo.com/phonebook.json?key=1c0fae70")!)
        
        return Single.create { single in
            URLSession.shared.dataTask(with: request) { (data, _, error) in
                if let error = error {
                    single(.error(error))
                } else if let data = data {
                    single(.success((try? JSONDecoder().decode([Contact].self, from: data)) ?? []))
                } else {
                    single(.success([]))
                }
            }.resume()
            
            return Disposables.create()
        }
    }
}

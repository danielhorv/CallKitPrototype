//
//  AppNavigator.swift
//  CallKitPrototype
//
//  Created by Daniel Horvath on 29.04.20.
//  Copyright © 2020 Daniel Horvath. All rights reserved.
//

import UIKit
import PrototypeKit
import CallKit
import RxSwift


class AppNavigator: Navigator, Flow {
    enum Destination {
        case contacts
    }
    
    var childScenes: [Flow] = []
    
    weak var appDelegate: AppDelegate?
    
    private let coreDataStore: CoreDataStore = CoreDataStore()
    
    private lazy var contactsProvider: ContactsProviderProtocol = MockContactsProvider(coreDataStore:  coreDataStore)
    
    private lazy var callDirectorySyncController = CallDirectorySyncController(coreDataStore: coreDataStore)
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }
    
    func start(on parent: Flow?) -> UIViewController? {
        navigate(to: .contacts)
        
        _ = callDirectorySyncController.syncState
            .debug()
            .subscribe()
        
        // Delay only for development
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.callDirectorySyncController.startSync()
        }
 
        return nil
    }
    
    func navigate(to destination: AppNavigator.Destination) {
        switch destination {
        case .contacts:
            let contactsViewController = ContactsViewController()
            contactsViewController.reactor = ContactsReactor(contactsProvider: contactsProvider, callDirectorySyncController: callDirectorySyncController)
            appDelegate?.window?.rootViewController = UINavigationController(rootViewController: contactsViewController)
        }
    }
}

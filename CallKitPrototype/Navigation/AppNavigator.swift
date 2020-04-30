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

class CallDirectorySyncController: NSObject {
    
    private let coreDataStore: CoreDataStore = CoreDataStore()
    
    func sync() {
        print("Sync started")
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "com.dhorvath.CallKitPrototype.CallExtension", completionHandler: { [weak self] error in
            print("inClosure")
            guard error == nil else {
                print("error: ", error?.localizedDescription ?? "")
                return
            }
            
            do {
                let batchCount = try self?.coreDataStore.loadUnsyncedContacts().count ?? 0
                if batchCount > 0 {
                    self?.sync()
                    print("nextBatch", batchCount)
                } else {
                    print("all contact synced")
                }
            } catch {
                print("Error reloading extension: \(error.localizedDescription)")
            }
        })
    }
}

class AppNavigator: Navigator, Flow {
    enum Destination {
        case contacts
    }
    
    var childScenes: [Flow] = []
    
    weak var appDelegate: AppDelegate?
    
    private let contactsProvider: ContactsProviderProtocol = MockContactsProvider()
    
    private let callDirectorySyncController = CallDirectorySyncController()
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }
    
    func start(on parent: Flow?) -> UIViewController? {
        navigate(to: .contacts)
        callDirectorySyncController.sync()
        return nil
    }
    
    func navigate(to destination: AppNavigator.Destination) {
        switch destination {
        case .contacts:
            let contactsViewController = ContactsViewController()
            contactsViewController.reactor = ContactsReactor(contactsProvider: contactsProvider)
            appDelegate?.window?.rootViewController = UINavigationController(rootViewController: contactsViewController)
        }
    }
}

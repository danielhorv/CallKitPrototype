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

enum SyncState {
    case initial
    case syncCreatedContacts(CGFloat)
    case syncDeletedContacts(CGFloat)
    case syncUpdatedContacts(CGFloat)
    case finished
    case cancelled
}

class CallDirectorySyncController: NSObject {
    
    private let coreDataStore: CoreDataStore
    
    public var isSynronising: Bool = false
    
    private var syncStateSubject = BehaviorSubject<SyncState>(value: .initial)
    
    private var isCancelled: Bool = false
    
    public var syncState: Observable<SyncState> {
        return syncStateSubject.asObservable()
    }
    
    public init(coreDataStore: CoreDataStore) {
        self.coreDataStore = coreDataStore
        
        print("numberOfDeletedContacts: ", coreDataStore.numberOfUnsyncedDeletedContacts)
        print("numberOfUpdatedContacts: ", coreDataStore.numberOfUnsyncedUpdatedContacts)
    }
    
    // unsyncedContacts need to be stored
    // because it's in PersistentProvider an ComputedProperty and
    // we need the initial count value of unsynced contacts
    private var unsyncedContacts: Int = 0
    
    
    // Start syncronization - reloadExtension until there are unsynced contacts
    public func startSync() {
        isCancelled = false
        unsyncedContacts = coreDataStore.numberOfUnsyncedContacts
        print(unsyncedContacts)
        sync()
    }
    
    public func stopSync() {
        isCancelled = true
        sync()
    }
    
    // this function called recursive
    private func sync() {
        guard !isCancelled else {
            syncStateSubject.onNext(.cancelled)
            return
        }
        
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "com.dhorvath.CallKitPrototype.CallExtension", completionHandler: { [weak self] error in
                self?.handleExtensionReloadCompletion(with: error)
        })
    }
    
    private func handleExtensionReloadCompletion(with error: Error?) {
        print(unsyncedContacts)
        
        guard error == nil else {
            syncStateSubject.onError(error!)
            print("error: ", error?.localizedDescription ?? "")
            return
        }
        
        if coreDataStore.numberOfUnsyncedCreatedContacts > 0 {
            coreDataStore.callDirectoryOperation = .loadAll
            syncStateSubject.onNext(.syncCreatedContacts(coreDataStore.percentage(for: unsyncedContacts)))
            self.sync()
            
        } else if coreDataStore.numberOfUnsyncedUpdatedContacts > 0 {
            coreDataStore.callDirectoryOperation = .update
            syncStateSubject.onNext(.syncUpdatedContacts(coreDataStore.percentage(for: unsyncedContacts)))
            self.sync()
            
        } else if coreDataStore.numberOfUnsyncedDeletedContacts > 0 {
            coreDataStore.callDirectoryOperation = .delete
            syncStateSubject.onNext(.syncDeletedContacts(coreDataStore.percentage(for: unsyncedContacts)))
            self.sync()
            
        } else {
            // Everithing is fine!
            syncStateSubject.onNext(.finished)
        }
    }
}

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

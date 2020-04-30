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
    case inProgress(CGFloat)
    case delete
    case update
    case finished
}

class CallDirectorySyncController: NSObject {
    
    private let coreDataStore: CoreDataStore
    
    public var isSynronising: Bool = false
    
    private var syncStateSubject = BehaviorSubject<SyncState>(value: .initial)
    
    public var syncState: Observable<SyncState> {
        return syncStateSubject.asObservable()
    }
    
    public init(coreDataStore: CoreDataStore) {
        self.coreDataStore = coreDataStore
        
        print("numberOfDeletedContacts: ", coreDataStore.numberOfDeletedContacts)
        print("numberOfUpdatedContacts: ", coreDataStore.numberOfUpdatedContacts)
    }
    
    public func sync() {
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "com.dhorvath.CallKitPrototype.CallExtension", completionHandler: { [weak self] error in
            DispatchQueue.main.async {
                self?.handleExtensionReloadCompletion(with: error)
            }
        })
    }
    
    private func handleExtensionReloadCompletion(with error: Error?) {
        guard error == nil else {
            syncStateSubject.onError(error!)
            print("error: ", error?.localizedDescription ?? "")
            return
        }
        
        do {
            if coreDataStore.numberOfUnSyncedContacts > 0 {
                coreDataStore.callDirectoryOperation = .loadAll
                syncStateSubject.onNext(.inProgress(coreDataStore.unSyncedContactsPercentage))
                self.sync()
    
            } else if coreDataStore.numberOfUpdatedContacts > 0 {
                coreDataStore.callDirectoryOperation = .update
                syncStateSubject.onNext(.update)
                self.sync()

            } else if coreDataStore.numberOfDeletedContacts > 0 {
                coreDataStore.callDirectoryOperation = .delete
                syncStateSubject.onNext(.delete)
                self.sync()
                
            } else {
                // Everithing is fine!
                syncStateSubject.onNext(.finished)
            }
        } catch {
            syncStateSubject.onError(error)
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
            self?.callDirectorySyncController.sync()
        }
        
        
        
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

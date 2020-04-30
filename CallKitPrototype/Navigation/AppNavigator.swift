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
    case inProgress(CGFloat)
    case finished
}

class CallDirectorySyncController: NSObject {
    
    private let coreDataStore: CoreDataStore = CoreDataStore()
    
    public var isSynronising: Bool = false
    
    private var syncStateSubject = PublishSubject<SyncState>()
//    public var syncState: Observable<Bool>
    
    public var syncState: Observable<SyncState> {
        return syncStateSubject.asObservable()
    }
    
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
                    self?.syncStateSubject.onNext(.inProgress(self?.coreDataStore.unSyncedContactsPercentage ?? 0))
                } else {
                    self?.syncStateSubject.onNext(.finished)
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
    
    private let coreDataStore: CoreDataStore = CoreDataStore()
    
    private lazy var contactsProvider: ContactsProviderProtocol = MockContactsProvider(coreDataStore:  coreDataStore)
    
    private let callDirectorySyncController = CallDirectorySyncController()
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }
    
    func start(on parent: Flow?) -> UIViewController? {
        navigate(to: .contacts)
        
        _ = callDirectorySyncController.syncState
            .debug()
            .subscribe()
//        callDirectorySyncController.sync()
        
        
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

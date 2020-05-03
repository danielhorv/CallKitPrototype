//
//  CallDirectorySyncController.swift
//  CallKitPrototype
//
//  Created by Daniel Horvath on 03.05.20.
//  Copyright © 2020 Daniel Horvath. All rights reserved.
//

import Foundation
import RxSwift
import CallKit
import PrototypeKit

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
    // because it's in PersistentProvider a ComputedProperty and
    // we need the initial count value of unsynced contacts
    private var unsyncedContacts: Int = 0
    
    
    // Start syncronization - reloadExtension until there are unsynced contacts
    public func startSync() {
        isCancelled = false
        unsyncedContacts = coreDataStore.numberOfUnsyncedContacts
        print(unsyncedContacts)
        sync()
    }
    
    // TODO: stopSync
    public func stopSync() {
        isCancelled = true
        sync()
    }
    
    // called recursive
    private func sync() {
        guard !isCancelled else {
            syncStateSubject.onNext(.cancelled)
            // TODO: need to kill the current async process
            return
        }
        
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: CallKitConfiguration.identifier, completionHandler: { [weak self] error in
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
            sync()
            
        } else if coreDataStore.numberOfUnsyncedUpdatedContacts > 0 {
            coreDataStore.callDirectoryOperation = .update
            syncStateSubject.onNext(.syncUpdatedContacts(coreDataStore.percentage(for: unsyncedContacts)))
            sync()
            
        } else if coreDataStore.numberOfUnsyncedDeletedContacts > 0 {
            coreDataStore.callDirectoryOperation = .delete
            syncStateSubject.onNext(.syncDeletedContacts(coreDataStore.percentage(for: unsyncedContacts)))
            sync()
            
        } else {
            // Everithing is fine!
            syncStateSubject.onNext(.finished)
        }
    }
}

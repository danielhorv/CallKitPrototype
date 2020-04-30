//
//  CallDirectoryHandler.swift
//  CallExtension
//
//  Created by Daniel Horvath on 29.04.20.
//  Copyright © 2020 Daniel Horvath. All rights reserved.
//

import Foundation
import CallKit
import PrototypeKit
import CoreData

class CallDirectoryHandler: CXCallDirectoryProvider {

//    private lazy var coreDataStore = CoreDataStore()
    
    override init() {
        super.init()
    }
    
    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // Check whether this is an "incremental" data request. If so, only provide the set of phone number blocking
        // and identification entries which have been added or removed since the last time this extension's data was loaded.
        // But the extension must still be prepared to provide the full set of data at any time, so add all blocking
        // and identification phone numbers if the request is not incremental.
//        if context.isIncremental {
//            addOrRemoveIncrementalBlockingPhoneNumbers(to: context)
//
//            addOrRemoveIncrementalIdentificationPhoneNumbers(to: context)
//        } else {
//            addAllBlockingPhoneNumbers(to: context)
//
//            addAllIdentificationPhoneNumbers(to: context)
//        }

        let coreDataStore = CoreDataStore()

//        do {

//        DispatchQueue.main.sync {
//            try? coreDataStore.loadUnsyncedContacts()
//            context.completeRequest()
//        }
            
//            try contacts.forEach {
//                context.addIdentificationEntry(withNextSequentialPhoneNumber: $0.callDirectoryPhoneNumber, label: $0.firstName + " " + $0.lastName)
////                try coreDataStore.markSynced(contact: $0)
//            }
//        } catch {
//            print(error)
//        }
//
        coreDataStore.container.viewContext.perform({ [weak self] in
            do {

                let contacts = try coreDataStore.loadUnsyncedContacts()
                try contacts.forEach {
                    context.addIdentificationEntry(withNextSequentialPhoneNumber: $0.callDirectoryPhoneNumber, label: $0.firstName + " " + $0.lastName)
                                    try coreDataStore.markSynced(contact: $0)
                }
                
                context.completeRequest()

            } catch {
                print(error)
                context.completeRequest()

            }
        })
    }

    private func addAllBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // Retrieve all phone numbers to block from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        //
        // Numbers must be provided in numerically ascending order.
        let allPhoneNumbers: [CXCallDirectoryPhoneNumber] = [ 1_408_555_5555, 1_800_555_5555 ]
        for phoneNumber in allPhoneNumbers {
            context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
        }
    }

    private func addOrRemoveIncrementalBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // Retrieve any changes to the set of phone numbers to block from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        let phoneNumbersToAdd: [CXCallDirectoryPhoneNumber] = [ 1_408_555_1234 ]
        for phoneNumber in phoneNumbersToAdd {
            context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
        }

//        let phoneNumbersToRemove: [CXCallDirectoryPhoneNumber] = [ 1_800_555_5555 ]
//        for phoneNumber in phoneNumbersToRemove {
//            context.removeBlockingEntry(withPhoneNumber: phoneNumber)
//        }

        // Record the most-recently loaded set of blocking entries in data store for the next incremental load...
    }

    private func addAllIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // Retrieve phone numbers to identify and their identification labels from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        //
        // Numbers must be provided in numerically ascending order.
        let allPhoneNumbers: [CXCallDirectoryPhoneNumber] = [ 1_877_555_5555, 1_888_555_5555 ]
        let labels = [ "Telemarketer", "Local business" ]

        for (phoneNumber, label) in zip(allPhoneNumbers, labels) {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
        }
    }

    private func addOrRemoveIncrementalIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // Retrieve any changes to the set of phone numbers to identify (and their identification labels) from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        let phoneNumbersToAdd: [CXCallDirectoryPhoneNumber] = [ 1_408_555_5678 ]
        let labelsToAdd = [ "New local business" ]

        for (phoneNumber, label) in zip(phoneNumbersToAdd, labelsToAdd) {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
        }

        let phoneNumbersToRemove: [CXCallDirectoryPhoneNumber] = [ 1_888_555_5555 ]

//        for phoneNumber in phoneNumbersToRemove {
//            context.removeIdentificationEntry(withPhoneNumber: phoneNumber)
//        }

        // Record the most-recently loaded set of identification entries in data store for the next incremental load...
    }

}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {

    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // An error occurred while adding blocking or identification entries, check the NSError for details.
        // For Call Directory error codes, see the CXErrorCodeCallDirectoryManagerError enum in <CallKit/CXError.h>.
        //
        // This may be used to store the error details in a location accessible by the extension's containing app, so that the
        // app may be notified about errors which occured while loading data even if the request to load data was initiated by
        // the user in Settings instead of via the app itself.
    }

}

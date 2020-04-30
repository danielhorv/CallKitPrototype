//
//  CoreDataStore.swift
//  PrototypeKit
//
//  Created by Daniel Horvath on 29.04.20.
//  Copyright © 2020 Daniel Horvath. All rights reserved.
//

import Foundation
import RxSwift
import CoreData

protocol CoreFetchable {
    static var entityName: String {get}
}
extension NSManagedObject: CoreFetchable {}

extension CoreFetchable where Self: NSManagedObject {
    static var entityName: String {
        return NSStringFromClass(self)
    }
}

private class CoreDataBundleHelper { }

public class CoreDataStore: NSObject {

//    public static let shared = CoreDataStore()
    
//    public let container: NSPersistentContainer
    
    public var contacts: [Contact] {
        do {
            let request: NSFetchRequest<CDContact> = CDContact.fetchRequest()
            return try self.container.viewContext.fetch(request)
                .map { Contact(cdContact: $0) }
        } catch {
            print(error)
            return []
        }
    }
    
    public lazy var container: NSPersistentContainer = {
        let bundle = Bundle(for: CoreDataBundleHelper.self)
        let group = "group.com.dhorvath.CallKitPrototype"
        let fileName = "Contacts.sqlite"
        
        let modelURL = bundle.url(forResource: "Contacts", withExtension: "momd")!
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
        
        guard let baseURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
            fatalError("Error creating base URL for \(group)")
        }
        
        let storeUrl = baseURL.appendingPathComponent(fileName)
        
        let container = NSPersistentContainer(name: "Contacts", managedObjectModel: managedObjectModel!)
        
        let description = NSPersistentStoreDescription()
        description.url = storeUrl
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            print(error.debugDescription)
        }
        
        return container
    }()
    
    public override init() {
        super.init()
    }
//    public override init() {
//        let bundle = Bundle(for: CoreDataBundleHelper.self)
//        let group = "group.com.dhorvath.CallKitPrototype"
//        let fileName = "Contacts.sqlite"
//
//        let modelURL = bundle.url(forResource: "Contacts", withExtension: "momd")!
//        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
////        let container = NSPersistentContainer(name: "Contacts", managedObjectModel: managedObjectModel!)
//
//        guard let baseURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
//            fatalError("Error creating base URL for \(group)")
//        }
//
//        let storeUrl = baseURL.appendingPathComponent(fileName)
//
//        let container = NSPersistentContainer(name: "Contacts", managedObjectModel: managedObjectModel!)
//
//        let description = NSPersistentStoreDescription()
//        description.url = storeUrl
//        container.persistentStoreDescriptions = [description]
//
//        container.loadPersistentStores { _, error in
//            print(error.debugDescription)
//        }
//
//        self.container = container
//        super.init()
//
//        print("contactNumber: ", contacts.count)
//    }

    public func loadUnsyncedContacts() throws -> [Contact] {
        let request: NSFetchRequest<CDContact> = CDContact.fetchRequest()
        request.fetchBatchSize = 4000
        request.fetchLimit = 4000
//        request.predicate = NSPredicate(format: "syncedWithCallDirectory==false")
    
        return try container.viewContext.fetch(request)
            .map { Contact(cdContact: $0) }
    }
    
    public func markSynced(contact: Contact) throws {
        let request: NSFetchRequest<CDContact> = CDContact.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", contact.id)
        
        if let cdContact = try container.viewContext.fetch(request).first {
            cdContact.syncedWithCallDirectory = true
            
            try container.viewContext.save()
        }
    }
    
    public func resetSyncState() throws {
        let request: NSFetchRequest<CDContact> = CDContact.fetchRequest()
        
        let contacts = try container.viewContext.fetch(request)
        contacts.forEach { $0.syncedWithCallDirectory = false }
        try container.viewContext.save()
    }
    
    public func object<T: NSManagedObject>(for type: T.Type, with predicate: NSPredicate, in context: NSManagedObjectContext) throws -> T? {
        let request: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.entityName)
        request.predicate = predicate
        
        return try context.fetch(request).first as? T
    }
    
    public func deleteAllItems<T: NSManagedObject>(for entity: T.Type, with predicate: NSPredicate) throws {
        let context = container.viewContext
        
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: T.entityName)
        request.predicate = predicate
        
        do {
            try context.fetch(request).forEach {
                guard let object = $0 as? T else { return }
                context.delete(object)
            }
            try context.save()
        } catch {
            print(error)
        }
    }
    
    private func deleteAllItems<T: NSManagedObject>(for entity: T.Type) throws {
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: T.entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        try container.persistentStoreCoordinator.execute(deleteRequest, with: container.newBackgroundContext())
    }
    
    public func storeOrUpdate(contact: Contact) throws {
        let context = container.viewContext
        
        var cdContact: CDContact!
        
        if let oldObject = (try? object(for: CDContact.self, with: NSPredicate(format: "id==%@", contact.id), in: context)) {
                cdContact = oldObject
        } else {
            cdContact = CDContact(context: context)
        }
        
        cdContact.id = contact.id
        cdContact.title = contact.title
        cdContact.firstName = contact.firstName
        cdContact.lastName = contact.lastName
        cdContact.department = contact.department
        cdContact.phoneNumber = contact.phoneNumber
        cdContact.mobileNumber = contact.mobileNumber
        cdContact.email = contact.email
        cdContact.statusRaw = contact.status.rawValue
        
        if cdContact.address != nil {
            cdContact.address?.city = contact.address?.city
            cdContact.address?.country = contact.address?.country
            cdContact.address?.street = contact.address?.street
            cdContact.address?.zipCode = contact.address?.zipCode
        } else {
            let cdAddress = CDAddress(context: context)
            cdAddress.city = contact.address?.city
            cdAddress.country = contact.address?.country
            cdAddress.street = contact.address?.street
            cdAddress.zipCode = contact.address?.zipCode
            cdContact.address = cdAddress
        }
        
        try context.save()
    }
}

extension CDContact {
    
    var status: ContactStatus {
        guard let statusRaw = statusRaw, let status = ContactStatus(rawValue: statusRaw) else {
            fatalError("ContactStatus not found")
        }
        
        return status
    }
}

extension Address {
    init(cdAddress: CDAddress) {
        street = cdAddress.street
        city = cdAddress.city
        zipCode = cdAddress.zipCode
        country = cdAddress.country
    }
}

extension Contact {
    init(cdContact: CDContact) {
        id = cdContact.id ?? ""
        title = cdContact.title
        firstName = cdContact.firstName ?? ""
        lastName = cdContact.lastName ?? ""
        department = cdContact.department
        phoneNumber = cdContact.phoneNumber
        mobileNumber = cdContact.mobileNumber
        email = cdContact.email
        
        if let cdAddress = cdContact.address {
            address = Address(cdAddress: cdAddress)
        } else {
            address = nil
        }
        
        status = cdContact.status
    }
}

//extension CoreDataStore: AppContactStore {
//    public var isEffectivelyEmpty: Bool {
//        return contacts.isEmpty
//    }
//
//    public var appContactsCount: Int {
//        return contacts.count
//    }
//
//    public var callDirectoryContactsCount: Int {
//        do {
//            let request: NSFetchRequest<CDContact> = CDContact.fetchRequest()
//            request.predicate = NSPredicate(format: "statusRaw != %@ AND callDirectoryNumber != nil", ContactStatus.deleted.rawValue)
//
//            return try container.viewContext.fetch(request)
//                .map { Contact(cdContact: $0) }
//                .count
//        } catch {
//            print(error)
//            return -1
//        }
//    }
//
//    public var contactsToDisplay: Single<[Contact]> {
//        return Single.just(contacts)
//    }
//
//    public func update(contacts: [Contact], isDelta: Bool) -> Completable {
//        return Completable.create { [weak self] completable in
//            do {
//                try contacts.forEach { try self?.storeOrUpdate(contact: $0) }
//            } catch {
//                completable(.error(error))
//            }
//            return Disposables.create()
//        }
//    }
//
//    public func removeDeletedContacts() -> Completable {
//        return Completable.create { [weak self] completable in
//            do {
//                let predicate = NSPredicate(format: "statusRaw == %@ AND syncedWithCallDirectory == true", ContactStatus.deleted.rawValue)
//                try self?.deleteAllItems(for: CDContact.self, with: predicate)
//                completable(.completed)
//            } catch {
//                completable(.error(error))
//            }
//            return Disposables.create()
//        }
//    }
//
//    public func deleteAllContacts() -> Completable {
//        return Completable.create { [weak self] completable in
//            do {
//                try self?.deleteAllItems(for: CDContact.self)
//                completable(.completed)
//            } catch {
//                completable(.error(error))
//            }
//            return Disposables.create()
//        }
//    }
//
//    public func markAllUnsynced() -> Completable {
//        let context = container.viewContext
//
//        return Completable.create { completable in
//            do {
//                let request: NSFetchRequest<CDContact> = CDContact.fetchRequest()
//                request.predicate = NSPredicate(format: "syncedWithCallDirectory == true")
//                let syncedContacts = try context.fetch(request)
//                syncedContacts.forEach { $0.syncedWithCallDirectory = true }
//                try context.save()
//            } catch {
//                completable(.error(error))
//            }
//            return Disposables.create()
//        }
//    }
//
//    // WTF
//    public func cloneContactsWithSecondaryNumbers() -> Completable {
//        return Completable.create { completable in
//            completable(.completed)
//            return Disposables.create()
//        }
//    }
//
//    // WTFF
//    public func preparePagingIndicesForCallDirectorySync() -> Completable {
//        return .empty()
//    }
//
//    // WTFFF
//    public func clearIndices() -> Completable {
//        return .empty()
//    }
//
//
//}

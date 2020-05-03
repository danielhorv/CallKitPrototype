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
    
    private struct Configuration {
        static let groupIdentifier = "group.com.dhorvath.CallKitPrototype"
        static let fileName = "Contacts.sqlite"
        static let modelName = "Contacts"
        static let containerName = "Contacts"
    }
    
    private lazy var container: NSPersistentContainer = {
        let bundle = Bundle(for: CoreDataBundleHelper.self)
        
        guard let modelURL = bundle.url(forResource: Configuration.modelName, withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        
        guard let baseURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Configuration.groupIdentifier) else {
            fatalError("Error creating baseURL for \(Configuration.groupIdentifier)")
        }
        
        let container = NSPersistentContainer(name: Configuration.containerName, managedObjectModel: managedObjectModel)
        
        let storeUrl = baseURL.appendingPathComponent(Configuration.fileName)

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
    
    public func resetSyncState() throws {
        let request: NSFetchRequest<CDContact> = CDContact.fetchRequest()
        
        let contacts = try container.viewContext.fetch(request)
        contacts.forEach { $0.syncedWithCallDirectory = false }
        try container.viewContext.save()
    }
    
    private func object<T: NSManagedObject>(for type: T.Type, with predicate: NSPredicate, in context: NSManagedObjectContext) throws -> T? {
        let request: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.entityName)
        request.predicate = predicate
        
        return try context.fetch(request).first as? T
    }
    
    private func deleteAllItems<T: NSManagedObject>(for entity: T.Type, with predicate: NSPredicate) throws {
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
}

// MARK: - PersistensStore extension

extension CoreDataStore: PersistentStore {
   
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
    
    public var callDirectoryOperation: CallDirectoryOperation {
        get {
            let request: NSFetchRequest<CDCallDirectoryOperation> = CDCallDirectoryOperation.fetchRequest()
            if let rawValue = try? container.viewContext.fetch(request).first?.rawValue, let operation = CallDirectoryOperation(rawValue: rawValue) {
                return operation
            } else {
                return .loadAll
            }
        }
        set {
            let request: NSFetchRequest<CDCallDirectoryOperation> = CDCallDirectoryOperation.fetchRequest()
            if let storedOperation = try? self.container.viewContext.fetch(request).first {
                storedOperation.rawValue = newValue.rawValue
            } else {
                let cdCallDirectoryOperation = CDCallDirectoryOperation(context: self.container.viewContext)
                cdCallDirectoryOperation.rawValue = newValue.rawValue
            }
            
            try? self.container.viewContext.save()
        }
    }
    
    public var numberOfContacts: Int {
        let request: NSFetchRequest<CDContact> = CDContact.fetchRequest()
        do {
            return try container.viewContext.count(for: request)
        } catch {
            print(error)
            return 0
        }
    }
    
    public var numberOfUnsyncedContacts: Int {
        let request: NSFetchRequest<CDContact> = CDContact.fetchRequest()
        request.predicate = NSPredicate(format: "syncedWithCallDirectory==false")

        do {
            return try container.viewContext.count(for: request)
        } catch {
            print(error)
            return 0
        }
    }
    
    public var numberOfUnsyncedUpdatedContacts: Int {
        let request: NSFetchRequest<CDContact> = CDContact.fetchRequest()
        request.predicate = NSPredicate(format: "statusRaw == %@ AND syncedWithCallDirectory==false", ContactStatus.updated.rawValue)

        do {
            return try container.viewContext.count(for: request)
        } catch {
            print(error)
            return 0
        }
    }
    
    public var numberOfUnsyncedDeletedContacts: Int {
        let request: NSFetchRequest<CDContact> = CDContact.fetchRequest()
        request.predicate = NSPredicate(format: "statusRaw == %@ AND syncedWithCallDirectory==false", ContactStatus.deleted.rawValue)

        do {
            return try container.viewContext.count(for: request)
        } catch {
            print(error)
            return 0
        }
    }
    
    public var numberOfUnsyncedCreatedContacts: Int {
        let request: NSFetchRequest<CDContact> = CDContact.fetchRequest()
        request.predicate = NSPredicate(format: "statusRaw == %@ AND syncedWithCallDirectory==false", ContactStatus.created.rawValue)

        do {
            return try container.viewContext.count(for: request)
        } catch {
            print(error)
            return 0
        }
    }
}

// MARK: - CallDirectoryProviderProtocol extension

extension CoreDataStore: CallDirectoryProviderProtocol {
    
    public func loadUnsyncedContacts(for status: ContactStatus) throws -> [Contact] {
        let request: NSFetchRequest<CDContact> = CDContact.fetchRequest()
        request.fetchBatchSize = CallKitConfiguration.batchSize
        request.fetchLimit =  CallKitConfiguration.batchSize
        request.sortDescriptors = [NSSortDescriptor(key: "mobileNumber", ascending: true)]
        request.predicate = NSPredicate(format: "statusRaw == %@ AND syncedWithCallDirectory==false", status.rawValue)
        
        return try container.viewContext.fetch(request)
            .map { Contact(cdContact: $0) }
    }
    
    public func markSynced(contact: Contact) throws {
        let request: NSFetchRequest<CDContact> = CDContact.fetchRequest()
        request.predicate = NSPredicate(format: "id==%@", contact.id)
        
        if let cdContact = try container.viewContext.fetch(request).first {
            cdContact.syncedWithCallDirectory = true
            
            try container.viewContext.save()
        }
    }
    
    public func delete(contact: Contact) throws {
        if let cdContact = try? object(for: CDContact.self, with: NSPredicate(format: "id==%@", contact.id), in: container.viewContext) {
            container.viewContext.delete(cdContact)
            try container.viewContext.save()
        }
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

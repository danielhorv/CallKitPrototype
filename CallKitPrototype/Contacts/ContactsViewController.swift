//
//  ContactsViewController.swift
//  CallKitPrototype
//
//  Created by Daniel Horvath on 29.04.20.
//  Copyright © 2020 Daniel Horvath. All rights reserved.
//

import UIKit
import TAReusableView
import RxSwift
import RxCocoa
import ReactorKit
import RxDataSources
import PrototypeKit

struct ContactSectionModel {
    let header: String
    var items: [Contact]
}

extension Contact: IdentifiableType {
    public typealias Identity = String

    public var identity: String {
        return id
    }
}

extension ContactSectionModel: AnimatableSectionModelType {

    typealias Identity = String
    
    var identity: String {
        return header
    }
    
    init(original: ContactSectionModel, items: [Contact]) {
        self = original
        self.items = items
    }
}

class ContactsViewController: UIViewController, View {
    var disposeBag = DisposeBag()
    
    typealias Reactor = ContactsReactor
    
    private let tableView: UITableView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.register(UITableViewCell.self)
        return $0
    }(UITableView(frame: .zero, style: .grouped))
    
    private var dataSource: RxTableViewSectionedAnimatedDataSource<ContactSectionModel>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        view.backgroundColor = .white
        view.layoutMargins = .zero
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
                                     tableView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                                     tableView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                                     tableView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)])
    }
    
    func bind(reactor: ContactsReactor) {
        let dataSource = RxTableViewSectionedAnimatedDataSource<ContactSectionModel>(configureCell: { _, tableView, IndexPath, contact -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(forIndexPath: IndexPath)
            cell.textLabel?.text = contact.firstName + " " + contact.lastName
            cell.detailTextLabel?.text = contact.phoneNumber
            return cell
        }, titleForHeaderInSection: {dataSource, section in
            return dataSource.sectionModels[section].header
        }, sectionIndexTitles: { dataSource in
            return dataSource.sectionModels.map { $0.header }
        })

        self.dataSource = dataSource
        
        reactor.state.map { $0.contacts }
            .distinctUntilChanged()
            .map { contacts in
                var dict = Dictionary(grouping: contacts) { $0.firstName.first }
                dict.sort(by: { $0.key?.lowercased() ?? "" < $1.key?.lowercased() ?? "" })
                return dict.map { ContactSectionModel(header: String($0.key!), items: $0.value) }
            }

            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
}
class ContactsReactor: Reactor {
    
    enum Action {
        case loadContacts
    }
    
    enum Mutation {
        case setContacts([Contact])
    }
    
    struct State {
        var contacts: [Contact] = []
    }
    
    private let contactsProvider: ContactsProviderProtocol
    
    let initialState = State()
    
    init(contactsProvider: ContactsProviderProtocol) {
        self.contactsProvider = contactsProvider
    }
    
    func transform(action: Observable<Action>) -> Observable<Action> {
        action.startWith(.loadContacts)
    }
    
    func mutate(action: ContactsReactor.Action) -> Observable<ContactsReactor.Mutation> {
        switch action {
        case .loadContacts:
            return contactsProvider.fetchContacts()
                .asObservable()
                .map { Mutation.setContacts($0) }
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setContacts(let contacts):
            newState.contacts = contacts
        }
        
        return newState
    }
}

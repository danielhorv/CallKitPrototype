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
import CallKit

class ContactsViewController: UIViewController, View {
    var disposeBag = DisposeBag()
    
    typealias Reactor = ContactsReactor
    
    private let tableView: UITableView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.register(UITableViewCell.self)
        return $0
    }(UITableView(frame: .zero, style: .grouped))
    
    private var dataSource: RxTableViewSectionedAnimatedDataSource<ContactSectionModel>?
    
    private let cancelSyncBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: nil, action: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        
        navigationItem.rightBarButtonItem = cancelSyncBarButtonItem
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
        
        cancelSyncBarButtonItem.rx.tap
            .map { _ in Reactor.Action.stopSync }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.contacts }
            .distinctUntilChanged()
            .map { contacts in
                let dict = Dictionary(grouping: contacts) { $0.firstName.first }.sorted(by: { $0.key?.lowercased() ?? "" < $1.key?.lowercased() ?? "" })
                return dict.map { ContactSectionModel(header: String($0.key!), items: $0.value) }
            }
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
}

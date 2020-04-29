//
//  Navigator.swift
//  CallKitPrototype
//
//  Created by Daniel Horvath on 29.04.20.
//  Copyright © 2020 Daniel Horvath. All rights reserved.
//

import UIKit

protocol Navigator: class {
    associatedtype Destination
    
    func navigate(to destination: Destination)
}

protocol Flow: class {
    
    var childScenes: [Flow] { get set }
    
    @discardableResult
    func start(on parent: Flow?) -> UIViewController?
    
    func finished(child: Flow)
}

extension Flow {
    func finished(child: Flow) {
        childScenes.removeAll(where: { $0 === child })
    }
}

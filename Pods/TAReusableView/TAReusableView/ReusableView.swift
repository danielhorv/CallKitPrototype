//
//  ReusableView.swift
//  ReusableView
//
//  Created by MarioHahn on 04/10/16.
//  Copyright © 2016 MarioHahn. All rights reserved.
//

import UIKit

public protocol ReusableView: class {
    static var defaultReuseIdentifier: String { get }
}

public extension ReusableView where Self: UIView {
    static var defaultReuseIdentifier: String {
        return NSStringFromClass(self)
    }
}

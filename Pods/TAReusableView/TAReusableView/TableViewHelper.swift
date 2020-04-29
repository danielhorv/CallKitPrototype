//
//  TableViewHelper.swift
//  ReusableView
//
//  Created by MarioHahn on 13/09/16.
//  Copyright © 2016 Tailored Media GmbH. All rights reserved.
//

import UIKit

extension UITableViewCell: ReusableView { }

extension UITableViewHeaderFooterView: ReusableView { }

public extension UITableView {
    func register<T: UITableViewCell>(_: T.Type) {
		self.register(T.self, forCellReuseIdentifier: T.defaultReuseIdentifier)
	}
	
    func register<T: UITableViewHeaderFooterView>(_: T.Type) {
		self.register(T.self, forHeaderFooterViewReuseIdentifier: T.defaultReuseIdentifier)
	}
	
    func dequeueReusableCell<T: UITableViewCell>(forIndexPath indexPath: IndexPath) -> T {
		guard let cell = self.dequeueReusableCell(withIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else {
			fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
		}
		
		return cell
	}
	
    func dequeueHeaderHeaderFooterView<T: UITableViewHeaderFooterView>() -> T {
		guard let cell = dequeueReusableHeaderFooterView(withIdentifier: T.defaultReuseIdentifier) as? T else {
			fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
		}
		
		return cell
	}
    
    func dequeueCellForClass<T: UITableViewCell>(_ type: T.Type, forIndexPath indexPath: IndexPath) -> T {
        self.register(type, forCellReuseIdentifier: type.defaultReuseIdentifier)
        return dequeueReusableCell(withIdentifier: type.defaultReuseIdentifier, for: indexPath) as! T
    }
}

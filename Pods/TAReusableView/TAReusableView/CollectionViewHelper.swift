//
//  CollectionViewHelper.swift
//  ReusableView
//
//  Created by Dominik Arnhof on 25.01.16.
//  Copyright © 2016 Tailored Media GmbH. All rights reserved.
//

import UIKit

extension UICollectionReusableView: ReusableView { }

public extension UICollectionView {
	
    func register<T: UICollectionViewCell>(_: T.Type) {
		self.register(T.self, forCellWithReuseIdentifier: T.defaultReuseIdentifier)
	}
	
    func register<T: UICollectionReusableView>(_: T.Type, ofKind kind: String) {
		self.register(T.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: T.defaultReuseIdentifier)
	}
	
    func dequeueReusableCell<T: UICollectionViewCell>(forIndexPath indexPath: IndexPath) -> T {
		guard let cell = self.dequeueReusableCell(withReuseIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else {
			fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
		}
		
		return cell
	}
	
    func dequeueReusableSupplementaryView<T: UICollectionReusableView>(forIndexPath indexPath: IndexPath, ofKind kind: String) -> T {
		guard let view = self.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else {
			fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
		}
		return view
	}
    
    func dequeueCellForClass<T: UICollectionViewCell>(_ type: T.Type, forIndexPath indexPath: IndexPath) -> T {
        self.register(type, forCellWithReuseIdentifier: type.defaultReuseIdentifier)
        return dequeueReusableCell(withReuseIdentifier: type.defaultReuseIdentifier, for: indexPath) as! T
    }
}

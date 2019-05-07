//
//  Realm+CascadeDeleting.swift
//
//  Created by Yurii Chudnovets on 2/13/19.
//

import Realm
import RealmSwift

public protocol CascadeDeletable: class {
    var propertiesToCascadeDelete: [String] { get }
}

public protocol CascadeDeleting: class {
    func delete<S: Sequence>(_ objects: S, cascading: Bool) where S.Iterator.Element: Object
    func delete<Entity: Object>(_ entity: Entity, cascading: Bool)
}

public struct WeakObject<T: AnyObject>: Equatable, Hashable {
    private let identifier: ObjectIdentifier
    weak var object: T?
    
    public init(_ object: T) {
        self.identifier = ObjectIdentifier(object)
        self.object = object
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.identifier.hashValue)
    }
    
    public static func ==(lhs: WeakObject, rhs: WeakObject) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension Realm: CascadeDeleting {
    public func delete<S: Sequence>(_ objects: S, cascading: Bool) where S.Iterator.Element: Object {
        for obj in objects {
            delete(obj, cascading: cascading)
        }
    }
    
    public func delete<Entity: Object>(_ entity: Entity, cascading: Bool) {
        if cascading {
            cascadingDelete(entity)
        } else {
            delete(entity)
        }
    }
}

private extension Realm {
    private func cascadingDelete(_ object: Object) {
        var toBeDeleted = Set<WeakObject<Object>>()
        toBeDeleted.insert(WeakObject(object))
        while !toBeDeleted.isEmpty {
            let element = toBeDeleted.removeFirst()
            guard let obj = element.object, !obj.isInvalidated else { continue }
            resolve(obj, toBeDeleted: &toBeDeleted)
            delete(obj)
        }
    }
    
    private func resolve(_ element: Object, toBeDeleted: inout Set<WeakObject<Object>>) {
        guard let deletable = element as? CascadeDeletable else { return }
        let propertiesToDelete = element.objectSchema.properties.filter {
            deletable.propertiesToCascadeDelete.contains($0.name)
        }
        propertiesToDelete.forEach {
            guard let value = element.value(forKey: $0.name) else { return }
            if let object = value as? Object {
                toBeDeleted.insert(WeakObject(object))
            } else if let list = value as? RealmSwift.ListBase {
                for index in 0..<list._rlmArray.count {
                    guard let object = list._rlmArray.object(at: index) as? Object else { continue }
                    toBeDeleted.insert(WeakObject(object))
                }
            }
        }
    }
}

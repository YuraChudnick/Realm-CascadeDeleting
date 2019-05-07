# Realm-CascadeDeleting
Extension for RealmSwift

## Requirements

- Swift 4.2+

## Usage
```swift

class Dog: Object {
    @objc dynamic var name = ""
    @objc dynamic var age = 0
}

class Person: Object {
    @objc dynamic var name = ""
    @objc dynamic var picture: Data? = nil
    let dogs = List<Dog>()
}

extension Person: CascadeDeletable {
    var propertiesToCascadeDelete: [String] {
        return ["dogs"]
    }
}

//save object person
let person = Person()
person.dogs.append(Dog())

let realm = try! Realm()
try! realm.write {
    realm.add(person)
}

//cascade delete object
try! realm.write {
    realm.delete(person, cascading: true)
}

```

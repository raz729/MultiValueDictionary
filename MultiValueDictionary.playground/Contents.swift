import Foundation

protocol MultiValueDictionaryProtocol : Sequence where Element == (Key, Value) {
    associatedtype Key
    associatedtype Value

    // Returns true if the collection is modified; false otherwise.
    // Must return false if (key, value) pair already exists in the dictionary.
    mutating func addElement(withKey: Key, andValue: Value) -> Bool

    // Returns any iterable sequence of values associated to a key or nil if key
    // is not in dictionary
    func getValues(forKey: Key) -> AnySequence<Value>?

    // Removes and returns key value tuple if exist, otherwise returns nil
    mutating func removeElement(forKey: Key, andValue: Value) -> (Key, Value)?

    // Removes all values associated to a key and returns them as any iterable
    // sequence or just returns nil if key is not in the dictionary
    mutating func removeValues(forKey: Key) -> AnySequence<Value>?

    // For conformance to the Sequence protocol your type will also have
    // to implement its own makeIterator() method so the dictionary
    // itself can be iterated (such as with a for loop) returning tuples
    // of key/value pairs on each iteration
}

struct MultiValueDictionary<Key, Value>: MultiValueDictionaryProtocol where Key: Hashable, Value: Hashable {
    
    typealias DictValue = Set<Value>
    typealias Dict = [Key: DictValue]
    
    private var dict: Dict = [:]

    mutating func addElement(withKey: Key, andValue: Value) -> Bool {
        var value = dict.removeValue(forKey: withKey) ?? Set<Value>()
        
        if value.contains(andValue) {
            return false
        }
        
        value.insert(andValue)
        dict.updateValue(value, forKey: withKey)
        
        return true
    }

    func getValues(forKey: Key) -> AnySequence<Value>? {
        guard let values = dict[forKey] else { return nil }
        return AnySequence(values)
    }

    mutating func removeElement(forKey: Key, andValue: Value) -> (Key, Value)? {
        guard var values = dict[forKey] else { return nil }
        guard let value = values.remove(andValue) else { return nil }
        
        dict.updateValue(values, forKey: forKey)
        
        return (forKey, value)
    }

    mutating func removeValues(forKey: Key) -> AnySequence<Value>? {
        guard let values = dict.removeValue(forKey: forKey) else { return nil }
        return AnySequence(values)
    }

    func makeIterator() -> MultiValueDictionaryIterator {
        return MultiValueDictionaryIterator(dict: dict)
    }

    struct MultiValueDictionaryIterator: IteratorProtocol {
        
        private var keyIterator: Dict.Keys.Iterator
        private var valueIterator: DictValue.Iterator?
        
        private var currentKey: Key?
        private var dict: [Key: Set<Value>]

        init(dict: [Key: DictValue]) {
            self.dict = dict
            
            keyIterator = dict.keys.makeIterator()
        }

        mutating func next() -> (Key, Value)? {
            if currentKey == nil {
                currentKey = keyIterator.next()
            }
            
            guard let key = currentKey else { return nil }
            
            if valueIterator == nil {
                valueIterator = dict[key]?.makeIterator()
            }
            
            guard let value = valueIterator?.next() else {
                self.currentKey = nil
                self.valueIterator = nil
                
                return next()
            }
            
            return (key, value)
        }
    }
}


var myDict = MultiValueDictionary<String, String>()
myDict.addElement(withKey: "key1", andValue: "key1: Value1")
myDict.addElement(withKey: "key1", andValue: "key1: Value2")
myDict.addElement(withKey: "key1", andValue: "key1: Value3")
myDict.addElement(withKey: "key2", andValue: "key2: Value1")
myDict.addElement(withKey: "key2", andValue: "key2: Value2")
myDict.addElement(withKey: "key2", andValue: "key2: Value3")
myDict.addElement(withKey: "key2", andValue: "key2: Value4")
myDict.addElement(withKey: "key3", andValue: "key3: Value1")
myDict.addElement(withKey: "key3", andValue: "key3: Value2")
myDict.addElement(withKey: "key3", andValue: "key3: Value3")
myDict.addElement(withKey: "key3", andValue: "key3: Value4")
myDict.addElement(withKey: "key3", andValue: "key3: Value5")

print(myDict)
myDict.forEach { item in
    print(item)
}

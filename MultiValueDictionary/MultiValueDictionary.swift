import Foundation

protocol MultiValueDictionary : Sequence where Element == (Key, Value) {
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
    
    // For conformance to the Sequence protocal your type will also have
    // to implement its own makeIterator() method so the dictionary
    // itself can be iterated (such as with a for loop) returning tuples
    // of key/value pairs on each iteration
}

struct MyDictionary<Key, Value>: MultiValueDictionary where Key: Hashable, Value: Hashable {
    
    typealias Key = Key
    typealias Value = Value
    
    private var elements: [Key: Set<Value>] = [:]
    
    struct Iterator: IteratorProtocol {

        typealias Element = (Key, Value)

        private var elements: [Key: Set<Value>]
        private var keyIndex: Dictionary<Key, Set<Value>>.Index?
        private var valueIndex: Set<Value>.Index?

        init(elements: [Key: Set<Value>]) {
            self.elements = elements
            self.keyIndex = elements.startIndex
        }

        mutating func next() -> (Key, Value)? {
            guard let keyIndex = keyIndex, elements.indices.contains(keyIndex) else { return nil }
            
            let values = elements[keyIndex].value
            if valueIndex == nil {
                valueIndex = values.startIndex
            }
            
            guard let valueIndex = valueIndex, values.indices.contains(valueIndex) else {
                self.keyIndex = elements.index(after: keyIndex)
                self.valueIndex = nil
                return next()
            }
            
            let key = elements[keyIndex].key
            let value = values[valueIndex]
            
            self.valueIndex = values.index(after: valueIndex)
            
            return (key, value)
        }
    }

    public mutating func addElement(withKey: Key, andValue: Value) -> Bool {
        guard let values = elements[withKey] else {
            elements[withKey] = [andValue]
            return true
        }
        
        if values.contains(andValue) {
            return false
        }
        
        elements[withKey]?.insert(andValue)
        
        return true
    }

    public func getValues(forKey: Key) -> AnySequence<Value>? {
        guard let values = elements[forKey] else { return nil }
        
        return AnySequence(values)
    }

    public mutating func removeElement(forKey: Key, andValue: Value) -> (Key, Value)? {
        guard var values = elements[forKey] else { return nil }
        guard let firstIndex = values.firstIndex(of: andValue) else { return nil }
        
        let value = values[firstIndex]
        values.remove(at: firstIndex)
        
        elements[forKey] = values
        
        return (forKey, value)
    }

    public mutating func removeValues(forKey: Key) -> AnySequence<Value>? {
        guard let values = elements[forKey] else { return nil }
        elements[forKey] = nil
        
        return AnySequence(values)
    }

    func makeIterator() -> Iterator {
        Iterator(elements: elements)
    }
}

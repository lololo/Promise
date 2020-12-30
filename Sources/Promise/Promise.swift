import Foundation

class PromiseCenter {
    static let share = PromiseCenter()
    fileprivate init() {}
    
    var promises : [String:Any] = [:]
}

open class Promise<T> {
    
    enum PromiseError : Error {
        case empty
    }
    
    enum State {
        case pending
        case fulfilled
        case rejected
    }
    
    let uuid = UUID().uuidString
    var state : State = .pending
    
    var holderQueue : DispatchQueue
    var queue : DispatchQueue = DispatchQueue(label: "PROMISE_QUEUE")
    
    var result: T? = nil
    var error : Error? = nil
    
    deinit {
        print("----------------")
    }
    
    public func then(_ next: @escaping (T) -> Void) throws {
        
        defer {
            PromiseCenter.share.promises.removeValue(forKey: self.uuid)
        }
        
        if let result = self.result {
            holderQueue.async {
                next(result)
            }
        }
        else if let error = self.error {
            throw error
        }
        else {
            throw PromiseError.empty
        }
    }
    
    public func then<K>(_ next: @escaping  (T) -> Promise<K>) throws -> Promise<K> {
        defer {
            PromiseCenter.share.promises.removeValue(forKey: self.uuid)
        }
        if let result = self.result {
            return next(result)
        }
        else if let error = self.error {
            throw error
        }
        else {
            throw PromiseError.empty
        }
    }
    
    public func then<K>(_ next:(T) -> K) throws -> Promise<K> {
        defer {
            PromiseCenter.share.promises.removeValue(forKey: self.uuid)
        }
        if let result = self.result {
            let r = next(result)
            return Promise<K> { (fulfile, _) in
                fulfile(r)
            }
        }
        else if let error = self.error {
            throw error
        }
        else {
            throw PromiseError.empty
        }
    }
    
    func `catch`() {
        
    }
    
    public init( resolution: @escaping ((T)->Void, (Error)->Void ) -> Void  ) {
        
        self.holderQueue = self.queue
        let fulfile : (T)->Void = { r in
            self.result = r
            print(r)
            self.state = .fulfilled
        }
        let reject : (Error) -> Void = { error in
            print(error)
            self.error = error
            self.state = .rejected
        }
        self.queue.async {
            resolution(fulfile, reject)
        }
        
        PromiseCenter.share.promises[self.uuid] = self
    }
    
}

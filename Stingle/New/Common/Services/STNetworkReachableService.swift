//
//  STNetworkReachableService.swift
//  Stingle
//
//  Created by Khoren Asatryan on 8/4/21.
//

import Foundation
import Network

protocol INetworkReachableServiceObserver: AnyObject {
    func networkReachable(reachable: STNetworkReachableService, didChange status: STNetworkReachableService.Status)
}

class STNetworkReachableService: NSObject {
    
    // MARK: - Basics
    static let shared = STNetworkReachableService()

    private(set) var networkStatus: Status = .none
    private var observer = STObserverEvents<INetworkReachableServiceObserver>()

    var isNetworkReachable: Bool {
        guard self.networkStatus != .none else {
            return true
        }
        return self.networkStatus != .notConnected
    }
    
    //MARK: - Public methods

    func start() {
        self.configurePathMonitor()
    }
    
    func addObserver(listener: INetworkReachableServiceObserver) {
        self.observer.addObject(listener)
    }
    
    func removeObserver(listener: INetworkReachableServiceObserver) {
        self.observer.removeObject(listener)
    }
    
    private override init() {
        super.init()
    }

    // MARK: - Private methods
    
    private func configurePathMonitor() {
        let queue = DispatchQueue.global(qos: .background)
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = {[weak self] path in
            var status: Status = .notConnected
            if path.status == .satisfied {
                if path.usesInterfaceType(.cellular) {
                    status = .cellular
                } else if path.usesInterfaceType(.wifi) {
                    status = .wifi
                } else if path.usesInterfaceType(.wiredEthernet) {
                    status = .wiredEthernet
                } else {
                    status = .other
                }
            }
            self?.networkStatus = status
            DispatchQueue.main.async {
                guard let weakSelf = self else {
                    return
                }
                NSObject.cancelPreviousPerformRequests(withTarget: weakSelf, selector: #selector(weakSelf.updateObserver), object: nil)
                weakSelf.perform(#selector(weakSelf.updateObserver), with: nil, afterDelay: 2)
            }
        }
        monitor.start(queue: queue)
    }
    
    @objc private func updateObserver() {
        for item in self.observer.objects {
            item.networkReachable(reachable: self, didChange: self.networkStatus)
        }
    }
}

extension STNetworkReachableService {
    
    enum Status: String {
        case none = "none"
        case notConnected = "notConnected"
        case wifi = "wifi"
        case cellular = "cellular"
        case wiredEthernet = "wiredEthernet"
        case other = "other"
        
        var hasInternet: Bool {
            return self == .wifi || self == .cellular || self == .wiredEthernet
        }
        
    }

}

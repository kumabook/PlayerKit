//
//  AppleMusicClient.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/09/01.
//

import Foundation
import StoreKit
import MediaPlayer
import ReactiveSwift
import Cider

@available(iOS 9.3, *)
public class AppleMusicClient {
    static var developerToken: String = "xxxx"
    open private(set) var countryCode: String?
    open private(set) var capability: SKCloudServiceCapability?
    open static var shared: AppleMusicClient = AppleMusicClient()
    open var cloudServiceController: SKCloudServiceController
    open var cider: CiderClient
    
    init() {
        cloudServiceController = SKCloudServiceController()
        cider = CiderClient(storefront: .unitedStates, developerToken: AppleMusicClient.developerToken)
    }
    public var authroizationStatus: SKCloudServiceAuthorizationStatus {
        return SKCloudServiceController.authorizationStatus()
    }
    
    public var canAddToCloudMusicLibrary: Bool {
        return capability?.contains(SKCloudServiceCapability.addToCloudMusicLibrary) ?? false
    }
    
    public var canPlayback: Bool {
        return capability?.contains(SKCloudServiceCapability.musicCatalogPlayback) ?? false
    }
    
    public var subscriptionEligible: Bool {
        if #available(iOS 10.1, *) {
            return capability?.contains(SKCloudServiceCapability.musicCatalogSubscriptionEligible) ?? false
        } else {
            return false
        }
    }
    
    public func fetchCountryCode() -> SignalProducer<String?, NSError> {
        return SignalProducer { (observer, disposable) in
            self.cloudServiceController.requestStorefrontIdentifier { (identifier, error) in
                if let error = error as NSError? {
                    observer.send(error: error)
                } else {
                    observer.send(value: identifier.flatMap {
                        $0.split(separator: "-").first
                        }.flatMap {
                            StoreFrontIDs[String($0)]
                    })
                    observer.sendCompleted()
                }
            }
        }
    }
    
    public func requestAuthorization() -> SignalProducer<SKCloudServiceAuthorizationStatus, NSError> {
        return SignalProducer { (observer, disposable) in
            SKCloudServiceController.requestAuthorization { (status: SKCloudServiceAuthorizationStatus) in
                observer.send(value: status)
                observer.sendCompleted()
            }
        }
    }
    
    public func requestCapabilities() -> SignalProducer<SKCloudServiceCapability, NSError> {
        return SignalProducer { (observer, disposable) in
            self.cloudServiceController.requestCapabilities { (capability: SKCloudServiceCapability, error: Error?) in
                if let error = error {
                    observer.send(error: error as NSError)
                    return
                }
                observer.send(value: capability)
                observer.sendCompleted()
            }
        }
    }
    
    public func connect(silent: Bool = false) -> SignalProducer<(), NSError> {
        var signal = SignalProducer<SKCloudServiceAuthorizationStatus, NSError>.empty
        switch authroizationStatus {
        case .authorized:
            signal = SignalProducer(value: authroizationStatus)
        default:
            if silent {
                signal = SignalProducer(error: NSError(domain: "musicfeeder", code: -999, userInfo: ["reason":"unauthorized"]))
            } else {
                signal = requestAuthorization()
            }
        }
        return signal.flatMap(.concat) { (status: SKCloudServiceAuthorizationStatus) -> SignalProducer<SKCloudServiceCapability, NSError> in
            return self.requestCapabilities()
            }.flatMap(.concat) { (capability: SKCloudServiceCapability) -> SignalProducer<(SKCloudServiceCapability, String?), NSError> in
                return self.fetchCountryCode().map {
                    return (capability, $0)
                }
            }.map { (capability, countryCode) in
                self.setAppleMusicCurrentCountry(capability: capability, countryCode: countryCode)
                return ()
        }
    }
    
    private func setAppleMusicCurrentCountry(capability: SKCloudServiceCapability, countryCode: String?) {
        self.capability  = capability
        self.countryCode = countryCode
        guard let countryCode = countryCode else { return }
        guard let storefront = Storefront(rawValue: countryCode) else { return }
        if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
            cider = CiderClient(storefront: storefront, developerToken: AppleMusicClient.developerToken)
        }
    }

    public func song(id: String) -> SignalProducer<Track, NSError> {
        return SignalProducer { (observer, disposable) in
            self.cider.song(id: id) { track, error in
                if let e = error {
                    observer.send(error: e as NSError)
                    return
                }
                if let t = track {
                    QueueScheduler.main.schedule {
                        observer.send(value: t)
                        observer.sendCompleted()
                    }
                }
            }
        }
    }
}

//
//  SpotifyAPIClient.swift
//  PlayerKitExample
//
//  Created by Hiroki Kumamoto on 2018/08/31.
//

import Foundation
import SafariServices
import Spotify
import SwiftyJSON
import ReactiveSwift
import Alamofire

public enum SpotifyError: Error {
    case networkError(NSError)
    case notLoggedIn
    case parseError
    case sessionExpired(NSError?)
    var title: String {
        return "Error with Spotify"
    }
    var message: String {
        switch self {
        case .notLoggedIn:
            return "Not logged in spotify"
        case .networkError(let e):
            return e.localizedDescription
        case .sessionExpired(_):
            return "session expired"
        default:
            return "Sorry, unknown error occured"
        }
    }
}

public protocol SpotifyAuthDelegate: class {
    func spotifyAuthDidLogin()
    func spotifyAuthDidFailToLogin()
    func spotifyAuthDidLogout()
}

public struct Token {
    public var accessToken: String
    public var tokenType:   String
    public var expiresIn:   Int64
    public var expiresAt:   Int64
    init(json: JSON) {
        accessToken = json["access_token"].stringValue
        tokenType   = json["token_type"].stringValue
        expiresIn   = json["expires_in"].int64Value
        expiresAt   = Int64(Date().timeIntervalSince1970) + expiresIn
    }
    public var isValid: Bool {
        return Int64(Date().timeIntervalSince1970) <= expiresAt
    }
}

open class SpotifyAPIClient: NSObject, SPTAudioStreamingDelegate {
    static var scopes       = [
        SPTAuthStreamingScope,
        SPTAuthPlaylistReadPrivateScope,
        SPTAuthPlaylistModifyPublicScope,
        SPTAuthPlaylistModifyPrivateScope,
        SPTAuthUserLibraryModifyScope,
        SPTAuthUserLibraryReadScope,
        SPTAuthUserFollowModifyScope,
        SPTAuthUserFollowReadScope,
        SPTAuthUserReadPrivateScope
    ]
    static var shared          = SpotifyAPIClient()
    static var clientId        = "xxxxx"
    static var clientSecret    = "xxxxx"
    static var tokenSwapUrl:    String?
    static var tokenRefreshUrl: String?
    static var redirectUrl     = "playerkit.example.spotify-auth://callback"
    static var isPremiumUser = false
    public fileprivate(set) var auth: SPTAuth!
    public var authDelegate: SpotifyAuthDelegate?
    public var player: SPTAudioStreamingController!
    public var user:   SPTUser? {
        didSet {
            switch user?.product ?? .unknown {
            case .premium:
                SpotifyAPIClient.isPremiumUser = true
            case .free, .unlimited, .unknown:
                SpotifyAPIClient.isPremiumUser = false
            }
        }
    }
    var authViewController: UIViewController?
    var token: Token?
    var disposable: Disposable?
    
    open static func setup() {
        let auth: SPTAuth           = SPTAuth.defaultInstance()
        auth.clientID               = clientId
        auth.requestedScopes        = scopes
        auth.redirectURL            = URL(string: redirectUrl)!
        auth.sessionUserDefaultsKey = "SpotifySession"
        auth.tokenSwapURL           = tokenSwapUrl.flatMap { URL(string: $0) }
        auth.tokenRefreshURL        = tokenRefreshUrl.flatMap { URL(string: $0) }
        shared.auth                 = auth
        let player                  = SPTAudioStreamingController.sharedInstance() as SPTAudioStreamingController
        player.delegate             = shared
        shared.player               = player
        if let session = auth.session {
            shared.renewSessionIfNeeded(session: session).startWithResult { result in
                switch result {
                case .success(let session):
                    shared.startIfUserIsPremium(with: session)
                case .failure(_):
                    print("Failed to renew session")
                }
            }
        } else {
            print("Spotify hasn't logged in yet")
        }
    }
    
    var isLoggedIn: Bool {
        guard let session = auth?.session else { return false }
        return session.isValid() && user != nil
    }
    
    var accessToken: String? {
        return auth.session?.accessToken ?? token?.accessToken
    }
    
    func fetchTokenWithClientCredentials() -> SignalProducer<Token, SpotifyError> {
        return SignalProducer { (observer, disposable) in
            let url = "https://accounts.spotify.com/api/token"
            var headers = ["Content-Type":"application/x-www-form-urlencoded"]
            if let header = Alamofire.Request.authorizationHeader(user: SpotifyAPIClient.clientId, password: SpotifyAPIClient.clientSecret) {
                headers[header.key] = header.value
            }
            let request = Alamofire.request(url, method: .post, parameters: ["grant_type":"client_credentials"], encoding: URLEncoding.default, headers: headers)
                .authenticate(user: SpotifyAPIClient.clientId, password: SpotifyAPIClient.clientSecret)
                .responseJSON {  response in
                    if let value = response.result.value {
                        observer.send(value: Token(json: JSON(value)))
                        observer.sendCompleted()
                        return
                    }
                    if let error = response.result.error as NSError?{
                        observer.send(error: SpotifyError.networkError(error))
                    } else {
                        observer.send(error: SpotifyError.parseError)
                    }
            }
            disposable.observeEnded() {
                request.cancel()
            }
        }
    }
    
    func fetchTokenIfNeeded() -> SignalProducer<(), SpotifyError> {
        guard let s = auth.session, let _ = s.accessToken else {
            guard let token = token, token.isValid else {
                return fetchTokenWithClientCredentials().map {
                    self.token = $0
                    return
                }
            }
            return SignalProducer(value: ())
        }
        return renewSessionIfNeeded(session: auth.session).map {
            self.startIfUserIsPremium(with: $0)
            return
        }
    }
    
    func logout() {
        user = nil
        if player.loggedIn {
            player.logout()
        } else {
            didLogout()
        }
    }
    func start(with session: SPTSession) throws {
        try player.start(withClientId: auth.clientID, audioController: nil, allowCaching: true)
        player.diskCache = SPTDiskCache(capacity: 1024 * 1024 * 64)
        player.login(withAccessToken: session.accessToken)
    }
    func close() {
        try? player.stop()
        user = nil
        auth.session = nil
        UserDefaults.standard.removeObject(forKey: auth.sessionUserDefaultsKey)
    }
    func startAuthenticationFlow(viewController: UIViewController) {
        let authURL = self.auth.spotifyWebAuthenticationURL()
        authViewController = SFSafariViewController(url: authURL!)
        viewController.present(authViewController!, animated: true, completion: {})
    }
    func handleURL(url: URL) -> Bool {
        if auth.canHandle(url) {
            auth.handleAuthCallback(withTriggeredAuthURL: url, callback: { (e: Error?, session: SPTSession?) in
                if let e = e as NSError? {
                    print("\(e)")
                }
                guard let session = session else { return }
                self.startIfUserIsPremium(with: session)
            })
            return true
        }
        return false
    }
    
    private func startIfUserIsPremium(with session: SPTSession) {
        self.disposable = self.fetchMe().on(failed: { error in
            self.close()
            self.authViewController?.dismiss(animated: true, completion: {})
            self.authViewController = nil;
            self.authDelegate?.spotifyAuthDidFailToLogin()
        }, value: { user in
            self.user = user
            switch user.product {
            case .premium:
                do {
                    try self.start(with: session)
                } catch {
                    self.didLogin()
                }
            case .free, .unlimited, .unknown:
                self.didLogin()
            }
        }).start()
    }
    
    private func didLogin() {
        self.authViewController?.dismiss(animated: true, completion: {})
        self.authViewController = nil;
        self.authDelegate?.spotifyAuthDidLogin()
    }
    private func didLogout() {
        close()
        authDelegate?.spotifyAuthDidLogout()
    }
    public func audioStreamingDidLogout(_ audioStreaming: SPTAudioStreamingController!) {
        didLogout()
    }
    public func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveError error: Error!) {
        if let e = error {
            print("spotify didReceiveError: \(e)")
            disposable = renewSessionIfNeeded(session: auth.session).startWithResult { result in
                switch result {
                case .success(_):
                    print("Succeeded in renewing session")
                case .failure(_):
                    print("Failed to renew session")
                }
            }
        }
    }
    public func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        didLogin()
    }
    public func audioStreamingDidEncounterTemporaryConnectionError(_ audioStreaming: SPTAudioStreamingController!) {
        print("spotify did encounter temporary connection error")
        disposable = renewSessionIfNeeded(session: auth.session).startWithResult { result in
            switch result {
            case .success(_):
                print("Succeeded in renewing session")
            case .failure(_):
                print("Failed to renew session")
            }
        }
    }

    fileprivate func validate(response: URLResponse) -> SpotifyError? {
        guard let r = response as? HTTPURLResponse else {
            return  .networkError(NSError(domain: "spotify", code: 0, userInfo: ["error": "Not HTTPURLResponse"]))
        }
        if r.statusCode < 200 && r.statusCode >= 400 {
            return  .networkError(NSError(domain: "spotify", code: r.statusCode, userInfo: ["error": r.statusCode]))
        }
        return nil
    }
    
    open func renewSessionIfNeeded(session: SPTSession) -> SignalProducer<SPTSession, SpotifyError> {
        if session.isValid() {
            return SignalProducer(value: session)
        }
        return SignalProducer { (observer, disposable) in
            self.auth.renewSession(session) { error, session in
                self.auth.session = session
                if let session = session {
                    observer.send(value: session)
                } else if let error = error {
                    observer.send(error: SpotifyError.sessionExpired(error as NSError))
                } else {
                    observer.send(error: SpotifyError.sessionExpired(nil))
                }
            }
        }
    }
    
    open func fetchMe() -> SignalProducer<SPTUser, SpotifyError> {
        return SignalProducer { (observer, disposable) in
            guard let s = self.auth.session, let accessToken = s.accessToken else {
                observer.send(error: .notLoggedIn)
                return
            }
            SPTUser.requestCurrentUser(withAccessToken: accessToken) { e, object in
                if let e = e as NSError? {
                    observer.send(error: .networkError(e))
                    return
                }
                if let user = object as? SPTUser {
                    observer.send(value: user)
                    observer.sendCompleted()
                } else {
                    observer.send(error: .parseError)
                }
            }
        }
    }
    open func track(from url: URL) -> SignalProducer<SPTTrack, SpotifyError> {
        return fetchTokenIfNeeded().flatMap(FlattenStrategy.concat) { () -> SignalProducer<SPTTrack, SpotifyError> in return SignalProducer { (observer, disposable) in
            guard let accessToken = self.accessToken else {
                observer.send(error: .notLoggedIn)
                return
            }
            SPTTrack.track(withURI: url, accessToken: accessToken, market: nil) { e, object in
                if let e = e as NSError? {
                    observer.send(error: .networkError(e))
                    return
                }
                if let t = object as? SPTTrack {
                    observer.send(value: t)
                    observer.sendCompleted()
                } else {
                    observer.send(error: .parseError)
                }
            }
            }}
    }
}

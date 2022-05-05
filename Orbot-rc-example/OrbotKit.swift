//
//  OrbotKit.swift
//  Orbot-rc-example
//
//  Created by Benjamin Erhart on 25.04.22.
//

import UIKit

/**
 SDK for interacting with [Orbot iOS](https://orbot.app/).

 It contains 2 types of methods:

 - UI commands: Will open the Orbot app at a specific place. You are able to hand over data, but can get no information back from Orbot.

 - REST API methods: The Orbot VPN network extension contains a small web server listening on `localhost` so apps can acquire
   some information about the state of Tor. This is only available when the VPN network extension is started, obviously.
 */
open class OrbotKit {

    /**
     Indicates the type of URL to create for UI links.
     */
    public enum UiUrlType {

        /**
         Use  `orbot:` scheme URLs. Always works, but subject to scheme hijacking. (Another app than Orbot can register that scheme, too.)
         */
        case orbotScheme

        /**
         Use `https://orbot.app/rc/` links. Safer, but may break esp. in Orbot development or when the
         `orbot.app` domain wasn't available during the installation of Orbot.

         - parameter noWeb: If `true`, the user will not be sent to the `orbot.app` website, in case Orbot is not installed.
         */
        case universalLink(noWeb: Bool)
    }

    /**
     Internal errors of this SDK.
     */
    public enum Errors: Error, LocalizedError {

        /**
         This error is used when Orbot answered with an HTTP status code outside the 200 range.
         */
        case httpError(statusCode: Int)

        /**
         This SDK should not but could throw this error under conditions where things become `nil` when they shouldn't
         or don't cast to objects to which they should.
         */
        case internalError

        public var errorDescription: String? {
            switch self {
            case .httpError(let statusCode):
                return "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))"

            case .internalError:
                return "OrbotKit internal error"
            }
        }
    }

    /**
     All UI commands supported by Orbot.
     */
    public enum UiCommand {

        /**
         Just show the main scene of the Orbot app.
         */
        case show

        /**
         Start the Network Extension, if not yet started.

         Note: The user has to have it installed, first.
         Don't assume, that the Tor VPN is (immediately) available after you called this.
         Use ``status(_:)`` to test, if Tor is running.
         */
        case start

        /**
         Show Orbot's settings scene.
         */
        case showSettings

        /**
         Show Orbot's bridge configuration scene.
         */
        case showBridges

        /**
         Show Orbot's authentication cookies scene.
         */
        case showAuth

        /**
         Show Orbot's authentication cookies scene and prefill an "add cookie" dialog with the given arguments.

         You don't need to provide all pieces. E.g. for the URL the second-level domain would be enough.
         Orbot will do its best to sanitize the arguments.

         - parameter url: An URL containing an onion service domain.
         - parameter key: The key for the given onion service.
         */
        case addAuth(url: String, key: String)

        /**
         Generate an Orbot UI URL for the given ``UiUrlType`` and arguments.

         - parameter type: The URL type to generate.
         - returns: a built URL from the parameters.
         */
        public func url(for type: UiUrlType) -> URL? {
            var urlc = URLComponents()
            let path: String

            switch self {
            case .show:
                path = "show"

            case .start:
                path = "start"

            case .showSettings:
                path = "show/settings"

            case .showBridges:
                path = "show/bridges"

            case .showAuth:
                path = "show/auth"

            case .addAuth(let url, let key):
                path = "add/auth"
                urlc.queryItems = [URLQueryItem(name: "url", value: url),
                                   URLQueryItem(name: "key", value: key)]
            }

            switch type {
            case .orbotScheme:
                urlc.scheme = "orbot"
                urlc.path = path

            case .universalLink:
                urlc.scheme = "https"
                urlc.host = "orbot.app"
                urlc.path = "/rc/\(path)"
            }

            return urlc.url
        }
    }

    /**
     All REST API endpoints supported by Orbot.
     */
    public enum RestEndpoint {
        case getInfo
        case getCircuits(host: String?)
        case closeCircuit(id: String)

        public var request: URLRequest? {
            var method = "GET"

            var urlc = URLComponents()
            urlc.scheme = "http"
            urlc.host = "localhost"
            urlc.port = 15182

            switch self {
            case .getInfo:
                urlc.path = "/info"

            case .getCircuits(let host):
                urlc.path = "/circuits"

                if let host = host {
                    urlc.queryItems = [URLQueryItem(name: "host", value: host)]
                }

            case .closeCircuit(let id):
                urlc.path = "/circuits/\(id)"
                method = "DELETE"
            }

            guard let url = urlc.url else {
                return nil
            }

            var request = URLRequest(url: url)
            request.httpMethod = method

            return request
        }
    }

    /**
     - parameter success: A Boolean value that indicates whether the operation completed successfully.
     */
    public typealias UICompletionHandler = ((_ success: Bool) -> Void)?


    /**
     A singleton instance of this class.
     */
    public static var shared = OrbotKit()


    /**
     To make sure you only talk to Orbot, and not some impersonating app, leave this set to `.universalLink`!
     */
    open var uiUrlType = UiUrlType.universalLink(noWeb: true)

    /**
     The  `URLSession` used for all HTTP REST requests.

     You can modify/exchange this, if you think you need to.
     */
    open lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil

        return URLSession(configuration: config)
    }()

    /**
     The `JSONDecoder` used for decoding the JSON payload received from Orbot.

     You can modify/exchange this, if you think you need to.
     */
    open lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        return decoder
    }()


    /**
     Test if Orbot is installed.

     IMPORTANT: You will need to register the `orbot` scheme in your Info.plist
     file under `LSApplicationQueriesSchemes` for this to evaluate to `true`!

     NOTE: We always test the `orbot` scheme for this to work, as the `https` scheme of course
     can always be opened and there is no way to test, if an app to handle the `orbot.app` domain is installed.

     Of course, there is a slight risk, that another app registered that scheme, so stay cautious!
     */
    open var installed: Bool {
        guard let url = URL(string: "orbot:show") else {
            return false
        }

        return UIApplication.shared.canOpenURL(url)
    }


    /**
     Open Orbot with a certain UI.

     - parameter command: The command to execute.
     - parameter completion: The block to execute when the operation finished.
     This block is executed asynchronously on your app's main thread.
     */
    open func open(_ command: UiCommand, _ completion: UICompletionHandler = nil) {
        guard let url = command.url(for: uiUrlType) else {
            DispatchQueue.main.async {
                completion?(false)
            }

            return
        }

        let options: [UIApplication.OpenExternalURLOptionsKey: Any]

        if case .universalLink(let noWeb) = uiUrlType {
            options = [.universalLinksOnly: noWeb]
        }
        else {
            options = [:]
        }

        UIApplication.shared.open(url, options: options, completionHandler: completion)
    }


    // MARK: Orbot REST API Methods

    /**
     Get Orbot status and some metadata.

     If the Orbot VPN is not running, this will synthesize an answer, as it can't answer itself, obviously.

     - parameter completion: Returns a ``Info`` object on success or an `Error` object, never both. This block is executed on the `session.delegateQueue`.
     - parameter info: Orbot status and metadata.
     - parameter error: Any errors from `URLSession`, `JSONDecoder` or HTTP answers which are not in the 200 range. (See ``Errors``.)
     */
    open func info(_ completion: @escaping (_ info: Info?, _ error: Error?) -> Void) {
        request(.getInfo) { (info: Info?, error: Error?) in
            var info = info
            var error = error

            if let nsError = error as? NSError {
                if nsError.code == -1004 /* "Could not connect to the server." */ {
                    info = Info(status: .stopped, name: nil, version: nil, build: nil)
                    error = nil
                }
            }

            completion(info, error)
        }
    }

    /**
     Get Tor circuit information.

     You can optionally provide a `host` argument to filter the circuits for most probable circuits used in a request for this host.

     Please note: The circuit used for Onion service requests can be clearly identified. For normal Internet requests, though, that information
     is not available, therefore a list of circuits with the most likely candidates will be returned, ordered by reversed timestamp.

     If you do a request and ask for the circuits right afterwards, it's highly likely, that the first circuit in the returned list was used.
     The longer you wait, the wronger the answer will be.

     If Orbot isn't running, `NSError.code == -1004` most likely will be returned.

     - parameter host: A host to filter answers by, to find the circuit which most likely was used for this request.
     - parameter completion: Returns a list of ``TorCircuit`` objects on success or an `Error` object, never both. This block is executed on the `session.delegateQueue`.
     - parameter circuits: A list of currently built ``TorCircuit``s used in non-internal requests.
     - parameter error: Any errors from `URLSession`, `JSONDecoder` or HTTP answers which are not in the 200 range. (See ``Errors``.)
     */
    open func circuits(host: String? = nil, _ completion: @escaping (_ circuits: [TorCircuit]?, _ error: Error?) -> Void) {
        request(.getCircuits(host: host), completion)
    }

    /**
     Tell Tor to close the circuit with the given ID.

     If a circuit with that ID existed and was closed, `success` will be `true`.
     If not, but everything else in the request was ok, a 404 HTTP error will be returned.

     If Orbot isn't running, most likely `NSError.code == -1004` will be returned.

     - parameter id: An identifier of a circuit which should be closed. (`TorCircuit.circuitId`)
     - parameter completion: Returns a boolean indicating success or failure and possibly an `Error` object to explain the reason for failure. This block is executed on the `session.delegateQueue`.
     - parameter success: `true` on success, `false` on failure.
     - parameter error: Any errors from `URLSession`, `JSONDecoder` or HTTP answers which are not in the 200 range. (See ``Errors``.)
     */
    open func closeCircuit(id: String, _ completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        request(.closeCircuit(id: id)) { (_: TorCircuit? /* To satisfy Swift. Server returns nothing! */, error: Error?) in
            if let error = error {
                return completion(false, error)
            }

            completion(true, nil)
        }
    }

    /**
     Tell Tor to close the given circuit.

     Convenience wrapper for  ``closeCircuit(id:_:)``

     If a circuit with the same ID you provided existed and was closed, `success` will be `true`.
     If not, but everything else in the request was ok, a 404 HTTP error will be returned.

     If Orbot isn't running, most likely `NSError.code == -1004` will be returned.

     - parameter circuit: An circuit which should be closed.
     - parameter completion: Returns a boolean indicating success or failure and possibly an `Error` object to explain the reason for failure. This block is executed on the `session.delegateQueue`.
     - parameter success: `true` on success, `false` on failure.
     - parameter error: Any errors from `URLSession`, `JSONDecoder` or HTTP answers which are not in the 200 range. (See ``Errors``.)
     */
    open func closeCircuit(circuit: TorCircuit, _ completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        guard let id = circuit.circuitId, !id.isEmpty else {
            session.delegateQueue.addOperation {
                completion(false, nil)
            }

            return
        }

        closeCircuit(id: id, completion)
    }


    // MARK: Private Methods

    /**
     Query a given ``RestEndpoint``, JSON-decode the result and return it or any errors happening.

     - parameter endpoint: The endpoint to query.
     - parameter completion: Returns the expected value or  an `Error` object, never both. This block is executed on the `session.delegateQueue`.
     */
    private func request<T: Decodable>(_ endpoint: RestEndpoint, _ completion: @escaping (T?, Error?) -> Void) {
        guard let request = endpoint.request else {
            session.delegateQueue.addOperation {
                completion(nil, Errors.internalError)
            }

            return
        }

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                return completion(nil, error)
            }

            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                return completion(nil, Errors.internalError)
            }

            if statusCode < 200 || statusCode >= 300 {
                return completion(nil, Errors.httpError(statusCode: statusCode))
            }

            let payload: T?

            if let data = data, data.count > 0 {
                do {
                    payload = try self.decoder.decode(T.self, from: data)
                }
                catch {
                    return completion(nil, error)
                }
            }
            else {
                payload = nil
            }

            completion(payload, nil)
        }

        task.resume()
    }
}

/**
 Orbot VPN status and metadata.
 */
public struct Info: Codable {

    enum Status: String, Codable {
        case stopped = "stopped"
        case starting = "starting"
        case started = "started"
    }

    /**
     The current status of the Orbot Tor VPN.
     */
    let status: Status

    /**
     The name of the network extension. (Should be "Tor VPN".)
     */
    let name: String?

    /**
     The current semantic version of Orbot.
     */
    let version: String?

    /**
     The build ID of Orbot.
     */
    let build: String?
}

/**
 Tor circuit metadata.
 */
public struct TorCircuit: Codable {

    /**
     The raw data this object is constructed from.
     */
    let raw: String?

    /**
    The circuit ID. Currently only numbers beginning with "1" but Tor spec says, that could change.
     */
    let circuitId: String?

    /**
     The circuit status. Typically "BUILT".
     */
    let status: String?

    /**
     The circuit path as a list of ``TorNode`` objects.
     */
    let nodes: [TorNode]?

    /**
     Build flags of the circuit.
    */
    let buildFlags: [String]?

    /**
     Circuit purpose. Should be one of "GENERAL", "HS_CLIENT_REND" or "HS_SERVICE_REND".
     All others should get filtered.
     */
    let purpose: String?

    /**
     Circuit hidden service state.
     */
    let hsState: String?

    /**
     The rendevouz query.

     Should be equal the onion address this circuit was used for minus the `.onion` postfix.
     */
    let rendQuery: String?

    /**
     The circuit's  timestamp at which the circuit was created or cannibalized.
     */
    let timeCreated: Date?

    /**
     The reason for failed or closed circuits. This should always be empty.
     */
    let reason: String?

    /**
     The remoteReason for failed or closed circuits. This should always be empty.
     */
    let remoteReason: String?

    /**
     The ``socksUsername`` and ``socksPassword`` fields indicate the credentials that were used by a
     SOCKS client to connect to Tor’s SOCKS port and initiate this circuit.
     */
    let socksUsername: String?

    /**
     The ``socksUsername`` and ``socksPassword`` fields indicate the credentials that were used by a
     SOCKS client to connect to Tor’s SOCKS port and initiate this circuit.
     */
    let socksPassword: String?
}

/**
 Tor node metadata.
 */
public struct TorNode: Codable {

    /**
     The fingerprint aka. ID of a Tor node.
     */
    let fingerprint: String?

    /**
     The nickname of a Tor node.
     */
    let nickName: String?

    /**
     The IPv4 address of a Tor node.
     */
    let ipv4Address: String?

    /**
     The IPv6 address of a Tor node.
     */
    let ipv6Address: String?

    /**
     The country code of a Tor node's country.
     */
    let countryCode: String

    /**
     The localized country name of a Tor node's country.
     */
    let localizedCountryName: String?
}

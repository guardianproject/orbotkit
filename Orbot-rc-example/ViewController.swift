//
//  ViewController.swift
//  Orbot-rc-example
//
//  Created by Benjamin Erhart on 19.04.22.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    enum UiUrlType {
        case orbotScheme

        case universalLink
    }

    @IBOutlet weak var tableView: UITableView?

    private static let cellReuseId = "cell-reuse-id"

    private var uiUrlType = UiUrlType.orbotScheme

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        8
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellReuseId)
            ?? UITableViewCell(style: .default, reuseIdentifier: Self.cellReuseId)

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Test if Orbot is installed"

        case 1:
            cell.textLabel?.text = "Start Orbot App"

        case 2:
            cell.textLabel?.text = "Start Orbot VPN"

        case 3:
            cell.textLabel?.text = "Show Settings"

        case 4:
            cell.textLabel?.text = "Show Bridge Settings"

        case 5:
            cell.textLabel?.text = "Show Auth Settings"

        case 6:
            cell.textLabel?.text = "Add an Auth Cookie"

        case 7:
            cell.textLabel?.text = "Query Status"

        default:
            cell.textLabel?.text = "You should not see this!"
        }

        return cell
    }


    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            testExistance()

        case 1:
            open(ui(for: "show"))

        case 2:
            open(ui(for: "start"))

        case 3:
            open(ui(for: "show/settings"))

        case 4:
            open(ui(for: "show/bridges"))

        case 5:
            open(ui(for: "show/auth"))

        case 6:
            open(ui(for: "add/auth", arguments: ["url": "http://example23472834zasd.onion","key": "12345678examplekey12345678"]))

        case 7:
            query(url(for: "status"))

        default:
            break
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }


    // MARK: Actions

    @IBAction func toggleUrlType(_ item: UIBarButtonItem) {
        switch uiUrlType {
        case .orbotScheme:
            uiUrlType = .universalLink
            item.image = UIImage(systemName: "network")

        case .universalLink:
            uiUrlType = .orbotScheme
            item.image = UIImage(systemName: "iphone")
        }
    }


    // MARK: Public Methods

    func show(_ message: String, _ title: String = "Result") {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "OK", style: .default))

            self.present(alert, animated: true)
        }
    }


    // MARK: Private Methods

    /**
     IMPORTANT: You will need to register the `orbot` scheme in your Info.plist
     file under `LSApplicationQueriesSchemes` for this to evaluate to `true`!

     NOTE: You will always need to use the `orbot` scheme for this to work, as the `https` scheme of course
     can always be opened and there is no way to test, if an app to handle the `orbot.app` domain is installed.

     Of course, there is a slight risk, that another app registered that scheme.

     So, to make sure you only talk to Orbot, use the universal link URL (https://orbot.app/rc/) instead for all other calls!
     */
    private func testExistance() {
        let result = UIApplication.shared.canOpenURL(URL(string: "orbot:show")!)

        show("Orbot is\(result ? "" : " not") installed.")
    }

    private func open(_ url: URL) {
        UIApplication.shared.open(url)
    }

    private func ui(for command: String, arguments: [String: String]? = nil) -> URL {
        var urlc = URLComponents()

        switch uiUrlType {
        case .orbotScheme:
            urlc.scheme = "orbot"
            urlc.path = command

        case .universalLink:
            urlc.scheme = "https"
            urlc.host = "orbot.app"
            urlc.path = "/rc/\(command)"
        }

        urlc.queryItems = arguments?.map { URLQueryItem(name: $0, value: $1) }

        print(urlc.url!)

        return urlc.url!
    }

    private func query(_ url: URL) {
        let request = URLRequest(url: url)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                return self.show(error?.localizedDescription ?? "No data")
            }

            let content = String(data: data, encoding: .utf8)

            let response = response as? HTTPURLResponse

            self.show(content ?? "(nil)", "Result: \(response?.statusCode ?? -1)")
        }

        task.resume()
    }

    private func url(for command: String...) -> URL {
        var urlc = URLComponents()
        urlc.scheme = "http"
        urlc.host = "localhost"
        urlc.port = 15182
        urlc.path = "/\(command.joined(separator: "/"))"

        print(urlc.url!)

        return urlc.url!
    }
}

//
//  ViewController.swift
//  OrbotKit
//
//  Created by Benjamin Erhart on 05/05/2022.
//  Copyright (c) 2022 Guardian Project. All rights reserved.
//

import UIKit
import OrbotKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, OrbotStatusChangeListener {

    @IBOutlet weak var tableView: UITableView?

    private static let cellReuseId = "cell-reuse-id"


    var tokenAlert: UIAlertController?

    private var lastCircuits = [OrbotKit.TorCircuit]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1

        case 1:
            return 7

        default:
            return 5
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return ""

        case 1:
            return "UI interaction"

        default:
            return "REST API"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellReuseId)
            ?? UITableViewCell(style: .default, reuseIdentifier: Self.cellReuseId)

        switch indexPath.section {
        case 0:
            cell.textLabel?.text = "Test if Orbot is installed"

        case 1:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Start Orbot App"

            case 1:
                cell.textLabel?.text = "Start Orbot VPN"

            case 2:
                cell.textLabel?.text = "Show Settings"

            case 3:
                cell.textLabel?.text = "Show Bridge Settings"

            case 4:
                cell.textLabel?.text = "Show Auth Settings"

            case 5:
                cell.textLabel?.text = "Add an Auth Cookie"

            default:
                cell.textLabel?.text = "Request Access Token"
            }

        default:
            if OrbotKit.shared.apiToken?.isEmpty ?? true {
                cell.selectionStyle = .none
                cell.isUserInteractionEnabled = false
                cell.textLabel?.isEnabled = false
            }
            else {
                cell.selectionStyle = .default
                cell.isUserInteractionEnabled = true
                cell.textLabel?.isEnabled = true
            }

            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Query Status"

            case 1:
                cell.textLabel?.text = "Query circuit(s) for torproject.org"

            case 2:
                cell.textLabel?.text = "Query circuit for 2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion"

            case 3:
                cell.textLabel?.text = "Close last queried circuits"

            default:
                cell.textLabel?.text = "Notify on status change"
            }
        }

        return cell
    }


    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            show("Orbot is\(OrbotKit.shared.installed ? "" : " not") installed.")

        case 1:
            switch indexPath.row {
            case 0:
                OrbotKit.shared.open(.show) { success in
                    if !success {
                        self.show("Link could not be opened!", "Error")
                    }
                }

            case 1:
                OrbotKit.shared.open(.start(callback: URL(string: "orbotkit-example:main"))) { success in
                    if !success {
                        self.show("Link could not be opened!", "Error")
                    }
                }

            case 2:
                OrbotKit.shared.open(.settings) { success in
                    if !success {
                        self.show("Link could not be opened!", "Error")
                    }
                }

            case 3:
                OrbotKit.shared.open(.bridges) { success in
                    if !success {
                        self.show("Link could not be opened!", "Error")
                    }
                }

            case 4:
                OrbotKit.shared.open(.auth) { success in
                    if !success {
                        self.show("Link could not be opened!", "Error")
                    }
                }

            case 5:
                OrbotKit.shared.open(.addAuth(url: "http://example23472834zasd.onion", key: "12345678examplekey12345678")) { success in
                    if !success {
                        self.show("Link could not be opened!", "Error")
                    }
                }

            default:
                OrbotKit.shared.open(.requestApiToken(needBypass: true, callback: URL(string: "orbotkit-example:token-callback"))) { success in
                    if !success {
                        return self.show("Link could not be opened!", "Error")
                    }

                    let alert = UIAlertController(title: "Access Token", message: nil, preferredStyle: .alert)
                    alert.addTextField { tf in
                        tf.clearButtonMode = .whileEditing
                        tf.placeholder = "Paste API token here"
                    }

                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                        self.tokenAlert = nil
                    })

                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        OrbotKit.shared.apiToken = self.tokenAlert?.textFields?.first?.text

                        self.reloadApiSection()

                        self.tokenAlert = nil
                    })

                    self.present(alert, animated: false)

                    self.tokenAlert = alert
                }
            }
        default:
            switch indexPath.row {
            case 0:
                OrbotKit.shared.info { info, error in
                    switch error {
                    case OrbotKit.Errors.httpError(403)?:
                        self.reloadApiSection()

                    case .some(let error):
                        print(error)

                        self.show(error.localizedDescription, "Error")

                    default:
                        self.show(info.debugDescription)
                    }
                }

            case 1:
                let task = OrbotKit.shared.session.dataTask(with: URL(string: "https://torproject.org")!) { data, response, error in
                    if let error = error {
                        return self.show(error.localizedDescription, "Error")
                    }

                    OrbotKit.shared.circuits(host: "torproject.org") { circuits, error in
                        switch error {
                        case OrbotKit.Errors.httpError(403)?:
                            self.reloadApiSection()

                        case .some(let error):
                            print(error)

                            self.show(error.localizedDescription, "Error")

                        default:
                            self.lastCircuits = circuits ?? []

                            self.show(self.lastCircuits.debugDescription)
                        }
                    }
                }
                task.resume()

            case 2:
                let task = OrbotKit.shared.session.dataTask(with: URL(string: "http://2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion")!)
                { data, response, error in
                    if let error = error {
                        return self.show(error.localizedDescription, "Error")
                    }

                    OrbotKit.shared.circuits(host: "2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion") { circuits, error in
                        switch error {
                        case OrbotKit.Errors.httpError(403)?:
                            self.reloadApiSection()

                        case .some(let error):
                            print(error)

                            self.show(error.localizedDescription, "Error")

                        default:
                            self.lastCircuits = circuits ?? []

                            self.show(self.lastCircuits.debugDescription)
                        }
                    }
                }
                task.resume()

            case 3:
                let group = DispatchGroup()
                var results = [String]()

                guard !lastCircuits.isEmpty else {
                    return show("No circuits to close, yet. Query some, first!", "Error")
                }

                for circuit in lastCircuits {
                    guard let id = circuit.circuitId, !id.isEmpty else {
                        continue
                    }

                    group.enter()

                    OrbotKit.shared.closeCircuit(id: id) { success, error in
                        if case OrbotKit.Errors.httpError(403)? = error {
                            self.reloadApiSection()
                        }

                        results.append("Circuit \(id): \(error?.localizedDescription ?? (success ? "success" : "failure"))")

                        group.leave()
                    }
                }

                group.wait()

                show(results.joined(separator: "\n\n"))

            default:
                let cell = tableView.cellForRow(at: indexPath)

                if cell?.accessoryType == .checkmark {
                    cell?.accessoryType = .none

                    OrbotKit.shared.removeStatusChangeListener(self)
                }
                else {
                    cell?.accessoryType = .checkmark

                    OrbotKit.shared.notifyOnStatusChanges(self)
                }
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }


    // MARK: OrbotStatusChangeListener

    func orbotStatusChanged(info: OrbotKit.Info) {
        show(info.description, "Orbot VPN Status Changed")
    }

    func statusChangeListeningStopped(error: Error) {
        DispatchQueue.main.async {
            self.tableView?.cellForRow(at: IndexPath(row: 4, section: 2))?.accessoryType = .none
        }

        if case OrbotKit.Errors.httpError(403) = error {
            reloadApiSection()
        }

        show("Error while listening for status changes:\n\n\(error)", "Error")
    }


    // MARK: Actions

    @IBAction func openStore(_ sender: UIBarButtonItem) {
        UIApplication.shared.open(OrbotKit.appStoreLink)
    }

    @IBAction func toggleUrlType(_ item: UIBarButtonItem) {
        switch OrbotKit.shared.uiUrlType {
        case .orbotScheme:
            OrbotKit.shared.uiUrlType = .universalLink(noWeb: true)
            item.image = UIImage(named: "network")

        case .universalLink:
            OrbotKit.shared.uiUrlType = .orbotScheme
            item.image = UIImage(named: "iphone")
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

    func reloadApiSection() {
        DispatchQueue.main.async {
            self.tableView?.reloadSections([2], with: .fade)
        }
    }
}

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

    @IBOutlet weak var uiUrlModeBt: UIBarButtonItem! {
        didSet {
            updateUiUrlModeButton()
        }
    }


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
            return 8

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
                cell.textLabel?.text = "Stop Orbot VPN"

                enable(cell, !(OrbotKit.shared.apiToken?.isEmpty ?? true))

            case 3:
                cell.textLabel?.text = "Show Settings"

            case 4:
                cell.textLabel?.text = "Show Bridge Settings"

            case 5:
                cell.textLabel?.text = "Show Auth Settings"

            case 6:
                cell.textLabel?.text = "Add an Auth Cookie"

            default:
                cell.textLabel?.text = "Request Access Token"
            }

        default:
            enable(cell, !(OrbotKit.shared.apiToken?.isEmpty ?? true))

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
                Task {
                    if await !OrbotKit.shared.open(.show) {
                        show("Link could not be opened!", "Error")
                    }
                }

            case 1:
                Task {
                    if await !OrbotKit.shared.open(.start(callback: URL(string: "orbotkit-example:started"))) {
                        show("Link could not be opened!", "Error")
                    }
                }

            case 2:
//                let token = OrbotKit.shared.apiToken ?? ""
                guard let token = OrbotKit.shared.apiToken else {
                    return show("Cannot stop without authorization token!", "Error")
                }

                Task {
                    if await !OrbotKit.shared.open(.stop(token: token, callback: URL(string: "orbotkit-example:stopped"))) {
                        show("Link could not be opened!", "Error")
                    }
                }

            case 3:
                Task {
                    if await !OrbotKit.shared.open(.settings) {
                        show("Link could not be opened!", "Error")
                    }
                }

            case 4:
                Task {
                    if await !OrbotKit.shared.open(.bridges) {
                        show("Link could not be opened!", "Error")
                    }
                }

            case 5:
                Task {
                    if await !OrbotKit.shared.open(.auth) {
                        show("Link could not be opened!", "Error")
                    }
                }

            case 6:
                Task {
                    if await !OrbotKit.shared.open(.addAuth(url: "http://example23472834zasd.onion", key: "12345678examplekey12345678")) {
                        show("Link could not be opened!", "Error")
                    }
                }

            default:
                Task {
                    let success = await OrbotKit.shared.open(.requestApiToken(needBypass: true, callback: URL(string: "orbotkit-example:token-callback")))

                    if !success {
                        return show("Link could not be opened!", "Error")
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

                        self.reloadSections()

                        self.tokenAlert = nil
                    })

                    present(alert, animated: false)

                    tokenAlert = alert
                }
            }
        default:
            switch indexPath.row {
            case 0:
                Task {
                    do {
                        let info = try await OrbotKit.shared.info()

                        show(info.debugDescription)
                    }
                    catch {
                        switch error {
                        case OrbotKit.Errors.httpError(403):
                            reloadSections()

                        default:
                            print(error)

                            show(error.localizedDescription, "Error")
                        }
                    }
                }

            case 1:
                let host = "torproject.org"

                Task {
                    do {
                        _ = try await OrbotKit.shared.session.data(from: URL(string: "https://\(host)")!)
                    }
                    catch {
                        return show(error.localizedDescription, "Error")
                    }

                    do {
                        let circuits = try await OrbotKit.shared.circuits(host: host)

                        lastCircuits = circuits ?? []

                        show(lastCircuits.debugDescription)

                    }
                    catch {
                        switch error {
                        case OrbotKit.Errors.httpError(403):
                            reloadSections()

                        default:
                            print(error)

                            show(error.localizedDescription, "Error")
                        }
                    }
                }

            case 2:
                let host = "2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion"

                Task {
                    do {
                        _ = try await OrbotKit.shared.session.data(from: URL(string: "http://\(host)")!)
                    }
                    catch {
                        return show(error.localizedDescription, "Error")
                    }

                    do {
                        let circuits = try await OrbotKit.shared.circuits(host: host)

                        lastCircuits = circuits ?? []

                        show(lastCircuits.debugDescription)
                    }
                    catch {
                        switch error {
                        case OrbotKit.Errors.httpError(403):
                            reloadSections()

                        default:
                            print(error)

                            show(error.localizedDescription, "Error")
                        }
                    }
                }

            case 3:
                var results = [String]()

                guard !lastCircuits.isEmpty else {
                    return show("No circuits to close, yet. Query some, first!", "Error")
                }

                Task {
                    for circuit in lastCircuits {
                        guard let id = circuit.circuitId, !id.isEmpty else {
                            continue
                        }

                        do {
                            let success = try await OrbotKit.shared.closeCircuit(id: id)

                            results.append("Circuit \(id): \(success ? "success" : "failure")")
                        }
                        catch {
                            if case OrbotKit.Errors.httpError(403) = error {
                                reloadSections()
                            }

                            results.append("Circuit \(id): \(error.localizedDescription)")
                        }
                    }

                    show(results.joined(separator: "\n\n"))
                }

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
        Task { @MainActor in
            self.tableView?.cellForRow(at: IndexPath(row: 4, section: 2))?.accessoryType = .none

            if case OrbotKit.Errors.httpError(403) = error {
                reloadSections()
            }

            show("Error while listening for status changes:\n\n\(error)", "Error")
        }
    }


    // MARK: Actions

    @IBAction func openStore(_ sender: UIBarButtonItem) {
        UIApplication.shared.open(OrbotKit.appStoreLink)
    }

    @IBAction func toggleUrlType(_ item: UIBarButtonItem) {
        switch OrbotKit.shared.uiUrlType {
        case .orbotScheme:
            OrbotKit.shared.uiUrlType = .universalLink(noWeb: true)

        case .universalLink(noWeb: _):
            OrbotKit.shared.uiUrlType = .failover

        case .failover:
            OrbotKit.shared.uiUrlType = .orbotScheme
        }

        updateUiUrlModeButton()
    }


    // MARK: Public Methods

    @MainActor
    func show(_ message: String, _ title: String = "Result") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default))

        present(alert, animated: true)
    }

    @MainActor
    func reloadSections() {
        var rows = [IndexPath(row: 2, section: 1)]

        if let tableView = tableView {
            for i in 0 ... self.tableView(tableView, numberOfRowsInSection: 2) {
                rows.append(IndexPath(row: i, section: 2))
            }
        }

        self.tableView?.reloadRows(at: rows, with: .fade)
    }

    func enable(_ cell: UITableViewCell, _ toggle: Bool) {
        cell.selectionStyle = toggle ? .default : .none
        cell.isUserInteractionEnabled = toggle
        cell.textLabel?.isEnabled = toggle
    }


    // MARK: Private Methods

    func updateUiUrlModeButton() {
        switch OrbotKit.shared.uiUrlType {
        case .orbotScheme:
            uiUrlModeBt.image = UIImage(named: "iphone")

        case .universalLink(noWeb: _):
            uiUrlModeBt.image = UIImage(named: "network")

        case .failover:
            uiUrlModeBt.image = UIImage(named: "bandage")
        }
    }
}

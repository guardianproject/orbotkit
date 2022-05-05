//
//  ViewController.swift
//  OrbotKit
//
//  Created by Benjamin Erhart on 05/05/2022.
//  Copyright (c) 2022 Guardian Project. All rights reserved.
//

import UIKit
import OrbotKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView?

    private static let cellReuseId = "cell-reuse-id"


    private var lastCircuits = [TorCircuit]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        11
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

        case 8:
            cell.textLabel?.text = "Query circuit(s) for torproject.org"

        case 9:
            cell.textLabel?.text = "Query circuit for 2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion"

        case 10:
            cell.textLabel?.text = "Close last queried circuits"

        default:
            cell.textLabel?.text = "You should not see this!"
        }

        return cell
    }


    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            show("Orbot is\(OrbotKit.shared.installed ? "" : " not") installed.")

        case 1:
            OrbotKit.shared.open(.show) { success in
                if !success {
                    self.show("Link could not be opened!", "Error")
                }
            }

        case 2:
            OrbotKit.shared.open(.start) { success in
                if !success {
                    self.show("Link could not be opened!", "Error")
                }
            }

        case 3:
            OrbotKit.shared.open(.showSettings) { success in
                if !success {
                    self.show("Link could not be opened!", "Error")
                }
            }

        case 4:
            OrbotKit.shared.open(.showBridges) { success in
                if !success {
                    self.show("Link could not be opened!", "Error")
                }
            }

        case 5:
            OrbotKit.shared.open(.showAuth) { success in
                if !success {
                    self.show("Link could not be opened!", "Error")
                }
            }

        case 6:
            OrbotKit.shared.open(.addAuth(url: "http://example23472834zasd.onion", key: "12345678examplekey12345678")) { success in
                if !success {
                    self.show("Link could not be opened!", "Error")
                }
            }

        case 7:
            OrbotKit.shared.info { info, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print(error)

                        return self.show(error.localizedDescription, "Error")
                    }

                    self.show(info.debugDescription)
                }
            }

        case 8:
            let task = OrbotKit.shared.session.dataTask(with: URL(string: "https://torproject.org")!) { data, response, error in
                if let error = error {
                    return self.show(error.localizedDescription, "Error")
                }

                OrbotKit.shared.circuits(host: "torproject.org") { circuits, error in
                    if let error = error {
                        return self.show(error.localizedDescription, "Error")
                    }

                    self.lastCircuits = circuits ?? []

                    self.show(self.lastCircuits.debugDescription)
                }
            }
            task.resume()

        case 9:
            let task = OrbotKit.shared.session.dataTask(with: URL(string: "http://2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion")!)
            { data, response, error in
                if let error = error {
                    return self.show(error.localizedDescription, "Error")
                }

                OrbotKit.shared.circuits(host: "2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion") { circuits, error in
                    if let error = error {
                        return self.show(error.localizedDescription, "Error")
                    }

                    self.lastCircuits = circuits ?? []

                    self.show(self.lastCircuits.debugDescription)
                }
            }
            task.resume()

        case 10:
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
                    results.append("Circuit \(id): \(error?.localizedDescription ?? (success ? "success" : "failure"))")

                    group.leave()
                }
            }

            group.wait()

            show(results.joined(separator: "\n\n"))

        default:
            break
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }


    // MARK: Actions

    @IBAction func toggleUrlType(_ item: UIBarButtonItem) {
        switch OrbotKit.shared.uiUrlType {
        case .orbotScheme:
            OrbotKit.shared.uiUrlType = .universalLink(noWeb: true)
            item.image = UIImage(systemName: "network")

        case .universalLink:
            OrbotKit.shared.uiUrlType = .orbotScheme
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
}

//
//  ItemViewController.swift
//  Whale
//
//  Created by Christian Braun on 01.09.18.
//  Copyright © 2018 KURZ Digital Solutions GmbH & Co. KG. All rights reserved.
//

import UIKit
import WebRTC

class ItemViewController: UIViewController {
    @IBOutlet fileprivate var tableViewFooterView: UIView!
    @IBOutlet fileprivate weak var itemsTableView: UITableView!
    @IBOutlet fileprivate weak var connectButton: UIButton!

    fileprivate var calleeId: String?

    fileprivate var items = [Item]()

    override func viewDidLoad() {
        super.viewDidLoad()
        itemsTableView.tableFooterView = tableViewFooterView
        itemsTableView.dataSource = self
        itemsTableView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        calleeId = nil
        CallManager.shared.delegate = self
        connectButton.isEnabled = false
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCallStartedNotification(notification:)),
            name: CallManager.CallManagerCallStartedNotification,
            object: nil)
        items = Item.items()
        itemsTableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(
            self,
            name: CallManager.CallManagerCallStartedNotification,
            object: nil)
    }

    // MARK: Actions

    @IBAction func connectButtonTouched(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showCallSegue", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? ViewController else {
            return
        }

        vc.calleeId = calleeId
    }

    @objc
    func handleCallStartedNotification(notification: Notification) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "showCallSegue", sender: nil)
        }
    }
}

extension ItemViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row].value
        return cell
    }

    // Mark: - UITableViewDelegate
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            items.remove(at: indexPath.row)
            Item.save(items)
            tableView.deleteRows(at: [indexPath], with: .left)
        }
    }
}

extension ItemViewController: CallManagerDelegate {
    func callManager(_ sender: CallManager, didReceiveLocalVideoCapturer localCapturer: RTCCameraVideoCapturer) {
    }

    func callManager(_ sender: CallManager, didReceiveRemoteVideoTrack remoteTrack: RTCVideoTrack) {
    }

    func callManager(_ sender: CallManager, userDidJoin userId: String) {
        DispatchQueue.main.async {
            self.calleeId = userId
            self.connectButton.isEnabled = true
        }
    }

    func callManager(_ sender: CallManager, didReceiveData data: Data) {
    }

    func callDidStart(_ sender: CallManager) {
    }

    func callDidEnd(_ sender: CallManager) {
        DispatchQueue.main.async {
            self.connectButton.isEnabled = false
        }
    }
}

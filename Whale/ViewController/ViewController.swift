//
//  ViewController.swift
//  Whale
//
//  Created by Christian Braun on 20.08.18.
//  Copyright © 2018 KURZ Digital Solutions GmbH & Co. KG. All rights reserved.
//

import UIKit
import WebRTC
import WAL
import SIPKeyboardManager

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet fileprivate weak var remoteVideoView: RTCEAGLVideoView!
    @IBOutlet fileprivate weak var localVideoView: RTCCameraPreviewView!

    @IBOutlet fileprivate weak var portraitRemoteVideoAspectRatioConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var landscapeRemoteVideoAspectRatioConstraint: NSLayoutConstraint!

    @IBOutlet fileprivate weak var textFieldTopConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var itemTextField: UITextField!

    var calleeId: String?
    fileprivate var keyboardManager: SIPKeyboardManager = SIPKeyboardManager()
    fileprivate var partnerItems = [Item]()

    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardManager.delegate = self
        remoteVideoView.delegate = self
        itemTextField.delegate = self

        CallManager.shared.delegate = self
        if let calleeId = calleeId {
           CallManager.shared.initiate(call: Call(handle: "Outgoing Whale Call", partnerId: calleeId))
        } else {
            CallManager.shared.currentConnection?.remoteVideoTrack?.add(remoteVideoView)
            sendOwnItems()
        }
        localVideoView.captureSession = CallManager.shared.currentConnection?.localCapturer?.captureSession
    }

    fileprivate func sendOwnItems() {
        guard let data = try? JSONEncoder().encode(Item.items()) else {
            fatalError()
        }

        CallManager.shared.send(data: data)
    }

    fileprivate func setRandomPartnerItem() {
        guard !partnerItems.isEmpty else {
            return
        }
        DispatchQueue.main.async {
            self.itemTextField.isEnabled = false
            self.itemTextField.text =
                self.partnerItems[Int(arc4random_uniform(UInt32(self.partnerItems.count)))]
                .value
        }
    }

    fileprivate func takeActionsForRightAnswer() {
        self.itemTextField.backgroundColor = UIColor.green

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.itemTextField.backgroundColor = UIColor.white
            self.setRandomPartnerItem()
        }
    }

    fileprivate func takeActionsForWrongAnswer() {
        self.itemTextField.backgroundColor = UIColor.red

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.itemTextField.backgroundColor = UIColor.white
        }
    }

    // MARK: - Actions

    @IBAction func hangupButtonTouched(_ sender: UIButton) {
        CallManager.shared.end()
        dismiss(animated: true, completion: nil)
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        guard let text = textField.text, !text.isEmpty else {
            return true
        }

        guard let itemData = try? JSONEncoder().encode(Item(value: text)) else {
            fatalError("Unable to encode Item")
        }
        CallManager.shared.send(data: itemData)
        return true
    }
}

extension ViewController: CallManagerDelegate {
    func callManager(_ sender: CallManager, didReceiveLocalVideoCapturer localCapturer: RTCCameraVideoCapturer) {
        localVideoView.captureSession = localCapturer.captureSession
    }

    func callManager(_ sender: CallManager, didReceiveRemoteVideoTrack remoteTrack: RTCVideoTrack) {
        remoteTrack.add(remoteVideoView)
    }

    func callManager(_ sender: CallManager, userDidJoin userId: String) {
    }

    func callManager(_ sender: CallManager, didReceiveData data: Data) {
        if let item = try? JSONDecoder().decode(Item.self, from: data) {
            DispatchQueue.main.async {
                let trimmedAndUppercasedText = self.itemTextField.text?.trimmingCharacters(
                    in: CharacterSet.whitespaces)
                    .uppercased()
                let trimmedAndUpperCasedItemValue = item.value.trimmingCharacters(
                    in: CharacterSet.whitespacesAndNewlines)
                    .uppercased()
                if trimmedAndUpperCasedItemValue == trimmedAndUppercasedText  {
                    self.takeActionsForRightAnswer()
                    CallManager.shared.send(data: Response.success.rawValue.data(using: .utf8)!)
                } else {
                    self.takeActionsForWrongAnswer()
                    CallManager.shared.send(data: Response.failure.rawValue.data(using: .utf8)!)
                }
            }
        } else if let items = try? JSONDecoder().decode([Item].self, from: data) {
            partnerItems = items
            setRandomPartnerItem()
        } else if let response = Response(rawValue: String(data: data, encoding: .utf8)!) {
            DispatchQueue.main.async {
                switch response {
                case .failure:
                    self.takeActionsForWrongAnswer()
                case .success:
                    self.takeActionsForRightAnswer()
                }
            }
        }
    }


    func callDidStart(_ sender: CallManager) {
    }

    func callDidEnd(_ sender: CallManager) {
        dismiss(animated: true, completion: nil)
    }
}

extension ViewController: RTCEAGLVideoViewDelegate {
    func videoView(_ videoView: RTCEAGLVideoView, didChangeVideoSize size: CGSize) {
        if size.height > size.width {
            landscapeRemoteVideoAspectRatioConstraint.isActive = false
            portraitRemoteVideoAspectRatioConstraint.isActive = true
        } else {
            portraitRemoteVideoAspectRatioConstraint.isActive = false
            landscapeRemoteVideoAspectRatioConstraint.isActive = true
        }
    }
}

extension ViewController: SIPKeyboardManagerDelegate {
    // MARK: - SIPKeyboardManagerDelegate
    func keyboardManager(_ keyboardManager: SIPKeyboardManager, updatingKeyboardFrameTo keyboardFrame: CGRect, withAnimationDuration animationDuration: TimeInterval) {
        // even when we get an animationduration of 0, we always want it to animate
        let animationDuration = max(animationDuration, 0.2)
        let keyboardOriginInViewCoordinates = view.convert(CGPoint(x: 0, y: keyboardFrame.minY), from: nil)
        textFieldTopConstraint.constant = keyboardOriginInViewCoordinates.y - 30
        UIView.animate(withDuration: animationDuration) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
}

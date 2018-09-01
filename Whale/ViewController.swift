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

class ViewController: UIViewController {

    @IBOutlet fileprivate weak var remoteVideoView: RTCEAGLVideoView!
    @IBOutlet fileprivate weak var localVideoView: RTCCameraPreviewView!

    @IBOutlet weak var portraitRemoteVideoAspectRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak var landscapeRemoteVideoAspectRatioConstraint: NSLayoutConstraint!

    fileprivate var connection: WebRTCConnection?
    // Only set when called
    fileprivate var callerId: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        let formatConstraints = WebRTCConnection.FormatConstraints(
            preferredWidth: 640,
            preferredHeight: 480)
        let config = WebRTCConnection.Config(signalingServerUrl: "ws://notimeforthat.org:8080/ws",
                                             turnServer: nil,
                                             stunServerUrl: nil,
                                             formatConstraints: formatConstraints)
        connection = WebRTCConnection(with: config, delegate: self)
        connection?.join(roomName: "Test")
        remoteVideoView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Actions

    @IBAction func hangupButtonTouched(_ sender: UIButton) {
        if connection?.state == .connectedWithPartner {
            connection?.disconnect()
        } else {
            guard let callerId = callerId else {
                return
            }
            connection?.answerIncomingCall(userId: callerId)
        }
    }
}

extension ViewController: WebRTCConnectionDelegate {
    // MARK: WebRTCConnectionDelegate
    func webRTCConnection(_ sender: WebRTCConnection, didReceiveDataChanelData data: Data) {
    }

    func didReceiveIncomingCall(_ sender: WebRTCConnection, from userId: String) {
        callerId = userId
    }

    func didDisconnect(_ sender: WebRTCConnection) {
        print("DidDisconnect")
    }

    func didOpenDataChannel(_ sender: WebRTCConnection) {
        print("DidOpenDataChannel")
    }

    func webRTCConnection(_ sender: WebRTCConnection, didReceiveLocalCapturer localCapturer: RTCCameraVideoCapturer) {
        localVideoView.captureSession = localCapturer.captureSession
    }

    func webRTCConnection(_ sender: WebRTCConnection, didReceiveRemoteVideoTrack remoteTrack: RTCVideoTrack) {
        remoteTrack.add(self.remoteVideoView)
    }

    func webRTCConnection(_ sender: WebRTCConnection, userDidJoin userId: String) {
        connection?.connect(toUserId: userId)
    }

    func webRTCConnection(_ sender: WebRTCConnection, didChange state: WebRTCConnection.State) {
        print(state)
    }
}

extension ViewController: RTCEAGLVideoViewDelegate {
    func videoView(_ videoView: RTCEAGLVideoView, didChangeVideoSize size: CGSize) {
        print(size)
        if size.height > size.width {
            landscapeRemoteVideoAspectRatioConstraint.isActive = false
            portraitRemoteVideoAspectRatioConstraint.isActive = true
        } else {
            portraitRemoteVideoAspectRatioConstraint.isActive = false
            landscapeRemoteVideoAspectRatioConstraint.isActive = true
        }
    }
}

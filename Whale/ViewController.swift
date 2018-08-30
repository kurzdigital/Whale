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
    var connection: WebRTCConnection?

    override func viewDidLoad() {
        super.viewDidLoad()
        let formatConstraints = WebRTCConnection.FormatConstraints(
            preferredWidth: 640,
            preferredHeight: 480)
        let config = WebRTCConnection.Config(signalingServerUrl: "ws://notimeforthat.org:8080/ws",
                                             turnServer: nil,
                                             stunServerUrl: nil,
                                             formatConstraints: formatConstraints)
//        let config = WebRTCConnection.Config(signalingServerUrl: "ws://10.199.1.147:8080/ws",
//                                             turnServer: nil,
//                                             stunServerUrl: nil)
        connection = WebRTCConnection(with: config, delegate: self)
        connection?.connect(roomName: "Test")
        remoteVideoView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.connection?.send(data: "Hallo nur ein Test".data(using: .utf8)!)
        }
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension ViewController: WebRTCConnectionDelegate {
    // MARK: WebRTCConnectionDelegate

    func webRTCConnection(_ sender: WebRTCConnection, didReceiveLocalCapturer localCapturer: RTCCameraVideoCapturer) {
        localVideoView.captureSession = localCapturer.captureSession
    }

    func webRTCConnection(_ sender: WebRTCConnection, didReceiveRemoteVideoTrack remoteTrack: RTCVideoTrack) {
        remoteTrack.add(self.remoteVideoView)
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


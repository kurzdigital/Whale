//
//  WebRTCConnection.swift
//  WAL
//
//  Created by Christian Braun on 20.08.18.
//  Copyright © 2018 KURZ Digital Solutions GmbH & Co. KG. All rights reserved.
//

import Foundation
import WebRTC

fileprivate let audioTrackId = "WaleAS01"
fileprivate let videoTrackId = "WaleVS01"
fileprivate let mediaStreamId = "WaleMS"

public protocol WebRTCConnectionDelegate: class {
    func webRTCConnection(_ sender: WebRTCConnection, didReceiveLocalCapturer localCapturer: RTCCameraVideoCapturer)
    func webRTCConnection(_ sender: WebRTCConnection, didReceiveRemoteVideoTrack remoteTrack: RTCVideoTrack)
    func webRTCConnection(_ sender: WebRTCConnection, didReceiveLocalAudioTrack remoteTrack: RTCAudioTrack)
    func webRTCConnection(_ sender: WebRTCConnection, didReceiveRemoteAudioTrack remoteTrack: RTCAudioTrack)
    func webRTCConnection(_ sender: WebRTCConnection, userDidJoin userId: String)
    func webRTCConnection(_ sender: WebRTCConnection, didChange state: WebRTCConnection.State)
    func didOpenDataChannel(_ sender: WebRTCConnection)
    func webRTCConnection(_ sender: WebRTCConnection, didReceiveDataChannelData data: Data)
    func didReceiveIncomingCall(_ sender: WebRTCConnection, from userId: String)
}

public class WebRTCConnection: NSObject {
    public enum State {
        case disconnected
        case connectingToSignalingServer
        case connectingWithPartner
        case connectedWithPartner
    }

    public var state = WebRTCConnection.State.disconnected {
        didSet {
            if oldValue != state {
                delegate?.webRTCConnection(self, didChange: state)
            }
        }
    }
    let config: Config

    fileprivate weak var delegate: WebRTCConnectionDelegate?
    fileprivate var spreedClient: SpreedClient?
    fileprivate let peerConnectionFactory = RTCPeerConnectionFactory()
    fileprivate var peerConnection: RTCPeerConnection?
    fileprivate var partnerId: String?

    fileprivate(set) public var localCapturer: RTCCameraVideoCapturer?
    fileprivate(set) public var remoteVideoTrack: RTCVideoTrack?
    fileprivate(set) public var localAudioTrack: RTCAudioTrack?
    fileprivate(set) public var remoteAudioTrack: RTCAudioTrack?
    fileprivate var datachannel: RTCDataChannel?


    fileprivate let mandatorySdpConstraints = RTCMediaConstraints(
        mandatoryConstraints:["OfferToReceiveAudio": "true",
                              "OfferToReceiveVideo": "true"],
        optionalConstraints: nil)

    public init(with config: Config, delegate: WebRTCConnectionDelegate) {
        self.config = config
        self.delegate = delegate
    }

    public func join(roomName: String) {
        spreedClient = SpreedClient(
            with: config.signalingServerUrl,
            roomName: roomName,
            delegate: self)

        let rtcConfig = RTCConfiguration()
        var iceServers = [RTCIceServer]()
        if let turnServer = config.turnServer {
            iceServers.append(RTCIceServer(
                urlStrings: [turnServer.url],
                username: turnServer.username,
                credential: turnServer.password))
        }
        if let stunServerUrl = config.stunServerUrl {
            iceServers.append(RTCIceServer(urlStrings: [stunServerUrl]))
        }

        rtcConfig.iceServers = iceServers

        peerConnection = peerConnectionFactory
            .peerConnection(
                with: rtcConfig,
                constraints: RTCMediaConstraints(
                    mandatoryConstraints: nil,
                    optionalConstraints: nil),
                delegate: self)

        state = .connectingToSignalingServer
        createMediaTracks()
    }

    public func connect(toUserId userId: String) {
        partnerId = userId
        createDataChannel()
        peerConnection?.offer(
        for: mandatorySdpConstraints) { sessionDescription, error in
            if let error = error {
                print(error)
                return
            }
            guard let sessionDescription = sessionDescription else {
                fatalError("Session Description empty")
            }

            self.peerConnection?.setLocalDescription(
                sessionDescription,
                completionHandler: { (error) in
                    if let error = error {
                        fatalError("Unable to set local description \(error)")
                    }
            })
            self.spreedClient?.send(
                offer: sessionDescription,
                to: userId)
        }
    }

    public func answerIncomingCall(userId: String) {
        partnerId = userId
        peerConnection?.answer(for: mandatorySdpConstraints) { sessionDescription, error in
            if let error = error {
                print(error)
                return
            }
            guard let sessionDescription = sessionDescription else {
                fatalError("Session Description empty")
            }

            self.peerConnection?.setLocalDescription(
                sessionDescription,
                completionHandler: { (error) in
                    if let error = error {
                        fatalError("Unable to set local description \(error)")
                    }
                    self.spreedClient?.send(
                        answer: sessionDescription,
                        to: userId)
            })
        }
    }

    public func disconnect() {
        localCapturer?.stopCapture()
        spreedClient?.disconnect()
        datachannel?.close()
        datachannel = nil
        localCapturer = nil
        remoteVideoTrack = nil
        localAudioTrack = nil
        remoteAudioTrack = nil
        partnerId = nil
        peerConnection?.close()
        peerConnection = nil
    }

    public func send(data: Data) {
        datachannel?.sendData(
            RTCDataBuffer(data: data, isBinary: false)
        )
    }

    fileprivate func createDataChannel() {
        let dataChannelConfig = RTCDataChannelConfiguration()
        dataChannelConfig.isOrdered = true

        datachannel = peerConnection?.dataChannel(
            forLabel: "WhaleDataChannel",
            configuration: dataChannelConfig)

        datachannel?.delegate = self
    }

    fileprivate func createMediaTracks() {
        #if !arch(i386) && !arch(x86_64)
        let audioSource = peerConnectionFactory.audioSource(
            with: RTCMediaConstraints(
                mandatoryConstraints: nil,
                optionalConstraints: nil))
        let audioTrack = peerConnectionFactory.audioTrack(
            with: audioSource,
            trackId: audioTrackId)
        let videoSource = peerConnectionFactory.videoSource()
        let videoTrack = peerConnectionFactory.videoTrack(
            with: videoSource,
            trackId: videoTrackId)

        localCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        guard let device = RTCCameraVideoCapturer
            .captureDevices()
            .first(where: {$0.position == .front}) else {
                fatalError()
        }

        let mediaStream = peerConnectionFactory
            .mediaStream(withStreamId: mediaStreamId)
        mediaStream.addAudioTrack(audioTrack)
        mediaStream.addVideoTrack(videoTrack)
        peerConnection?.add(mediaStream)
        localAudioTrack = audioTrack
        delegate?.webRTCConnection(self, didReceiveLocalAudioTrack: audioTrack)

        let format = RTCCameraVideoCapturer.format(
            for: device,
            constraints: config.formatConstraints)
        localCapturer?.startCapture(
            with: device,
            format: format,
            fps: RTCCameraVideoCapturer.fps(for: format))
        delegate?.webRTCConnection(self, didReceiveLocalCapturer: localCapturer!)
        #endif
    }
}

extension WebRTCConnection: SpreedClientDelegate {
    func connectionDidClose(_ sender: SpreedClient) {
        // Do nothing
    }

    // MARK: - SpreedClientDelegate
    func isReadyToConnectToRoom(_ sender: SpreedClient) {
        spreedClient?.connect()
    }

    func spreedClient(_ sender: SpreedClient, userDidLeave userId: String) {
        spreedClient?.disconnect()
        disconnect()
    }

    func spreedClient(_ sender: SpreedClient, userDidJoin userId: String) {
        delegate?.webRTCConnection(self, userDidJoin: userId)
    }

    func spreedClient(_ sender: SpreedClient,
                      didReceiveOffer offer: RTCSessionDescription,
                      from userId: String) {
        self.peerConnection?.setRemoteDescription(offer, completionHandler: { error in
            if let error = error {
                fatalError("Unable to set remote description \(error)")
            }
        })
        delegate?.didReceiveIncomingCall(self, from: userId)

    }

    func spreedClient(_ sender: SpreedClient,
                      didReceiveAnswer answer: RTCSessionDescription,
                      from userId: String) {
        peerConnection?.setRemoteDescription(answer, completionHandler: { error in
            if let error = error {
                fatalError("Unable to set remote description \(error)")
            }
        })
    }

    func spreedClient(_ sender: SpreedClient, didReceiveCandidate candidate: RTCIceCandidate, from userId: String) {
        peerConnection?.add(candidate)
    }
}

extension WebRTCConnection: RTCPeerConnectionDelegate {
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print(#function)
        switch stateChanged {
        case .stable,
             .haveLocalOffer,
             .haveLocalPrAnswer,
             .haveRemoteOffer,
             .haveRemotePrAnswer:
            print("Other State")
        case .closed:
            print("Signaling closed")
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print(#function)
        if let remoteVideoTrack = stream.videoTracks.first {
            self.remoteVideoTrack = remoteVideoTrack
            delegate?.webRTCConnection(self, didReceiveRemoteVideoTrack: remoteVideoTrack)
        }
        if let remoteAudioTrack = stream.audioTracks.first {
            self.remoteAudioTrack = remoteAudioTrack
            delegate?.webRTCConnection(self, didReceiveLocalAudioTrack: remoteAudioTrack)
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print(#function)
    }

    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print(#function)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print(#function)
        switch newState {
        case .new:
            print("New")
        case .checking:
            print("Checking")
            state = .connectingWithPartner
        case .connected:
            print("Connected")
            state = .connectedWithPartner
        case .completed:
            print("Completed")
        case .failed:
            state = .disconnected
            print("Failed")
        case .disconnected:
            state = .disconnected
            print("Disconnected")
        case .closed:
            print("Closed")
            state = .disconnected
        case .count:
            print("Count")
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print(#function)

        switch newState {
        case .new:
            print("new ice gathering")
        case .gathering:
            print("gathering")
        case .complete:
            print("complete ice gathering")
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print(#function)
        guard let partnerId = partnerId else {
            fatalError("Can't send candidate without partner")
        }
        spreedClient?.send(candidate, to: partnerId)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print(#function)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print(#function)
        print("DataChannel opened")
        self.datachannel = dataChannel
        self.datachannel?.delegate = self
    }
}

extension WebRTCConnection: RTCDataChannelDelegate {
    public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        switch datachannel!.readyState {
        case .connecting:
            print("DataChannel connecting")
        case .open:
            print("DataChannel open")
            delegate?.didOpenDataChannel(self)
        case .closing:
            print("DataChannel closing")
        case .closed:
            print("DataChannel closed")
        }
    }

    public func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        delegate?.webRTCConnection(self, didReceiveDataChannelData: buffer.data)
    }
}

//
//  SpreedClient.swift
//  WAL
//
//  Created by Christian Braun on 21.08.18.
//

import Foundation
import Starscream
import WebRTC

protocol SpreedClientDelegate: class {
    func isReadyToConnectToRoom(_ sender: SpreedClient)
    func spreedClient(_ sender: SpreedClient, userDidJoin userId: String)
    func spreedClient(_ sender: SpreedClient, userDidLeave userId: String)
    func spreedClient(
        _ sender: SpreedClient,
        didReceiveOffer offer: RTCSessionDescription,
        from userId: String)
    func spreedClient(_ sender: SpreedClient,
                      didReceiveAnswer answer: RTCSessionDescription,
                      from userId: String)
    func spreedClient(_ sender: SpreedClient,
                      didReceiveCandidate candidate: RTCIceCandidate,
                      from userId: String)
    func connectionDidClose(_ sender: SpreedClient)
}

class SpreedClient: WebSocketDelegate {
    fileprivate let ws: WebSocket
    fileprivate var me: MeSignalingMessage?

    fileprivate weak var delegate: SpreedClientDelegate?
    fileprivate var roomName: String

    init(with url: String, roomName: String, delegate: SpreedClientDelegate) {
        self.delegate = delegate
        self.roomName = roomName
        ws = WebSocket(url: URL(string: url)!)
        ws.delegate = self
        ws.connect()
    }

    func connect() {
        guard me != nil else {
            return
        }
        let hello = HelloSignalingMessage(
            hello: HelloSignalingMessage.Hello(
                version: "1.0.0",
                userAgent: "iOS",
                roomName: roomName))

        guard let data = try? JSONEncoder().encode(hello) else {
            fatalError("Unable to encode HelloSignalingMessage")
        }

        send(data: data)
    }

    func disconnect() {
        ws.disconnect()
    }

    func send(offer: RTCSessionDescription, to userId: String) {
        let offerSignalingMessage = OfferSignalingMessage(
            offer: OfferSignalingMessage.OfferContainer(
                to: userId,
                offer: SessionDescription(from: offer)))

        guard let data = try? JSONEncoder().encode(offerSignalingMessage) else {
            fatalError("Unable to encode OfferSignalingMessage")
        }
        send(data: data)
    }

    func send(answer: RTCSessionDescription, to userId: String) {
        let answerSignalingMessage = AnswerSignalingMessage(
            answer: AnswerSignalingMessage.AnswerContainer(
                to: userId,
                answer: SessionDescription(from: answer)))

        guard let data = try? JSONEncoder().encode(answerSignalingMessage) else {
            fatalError("Unable to encode OfferSignalingMessage")
        }
        send(data: data)
    }

    func send(_ candidate: RTCIceCandidate, to userId: String) {
        let candidateSignalingMessage = CandidateSignalingMessage(
            candidate: CandidateSignalingMessage.CandidateContainer(
                to: userId,
                candidate: Candidate(from: candidate)))

        guard let data = try? JSONEncoder().encode(candidateSignalingMessage) else {
            fatalError("Unable to encode CandidateSignalingMessage")
        }
        send(data: data)
    }

    func send(data: Data) {
        let dataAsString = String(data: data, encoding: .utf8)!
        ws.write(string: dataAsString)
    }

    // MARK: - WebSocketDelegate

    func websocketDidConnect(socket: WebSocketClient) {
        print("Websocket connected")
    }

    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("Websocket disconnected")
        delegate?.connectionDidClose(self)
    }

    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        guard let data = text.data(using: .utf8) else {
            fatalError("Wrong encoding for received message")
        }

        if let meCarrier = try? JSONDecoder().decode(
            Carrier<MeSignalingMessage>.self,
            from: data) {
            me = meCarrier.data
            delegate?.isReadyToConnectToRoom(self)
            print("Received Self Message")
        } else if let _ = try? JSONDecoder().decode(
            Carrier<WelcomeSignalingMessage>.self,
            from: data) {
            print("Received Welcome")
        } else if let joinedCarrier = try? JSONDecoder().decode(
            Carrier<JoinedSignalingMessage>.self,
            from: data) {
            delegate?.spreedClient(self, userDidJoin: joinedCarrier.data.id)
            print("Received Joined")
        } else if let offerCarrier = try? JSONDecoder().decode(
            Carrier<OfferSignalingMessage.OfferContainer>.self,
            from: data) {
            delegate?.spreedClient(
                self,
                didReceiveOffer: offerCarrier.data.offer.toRTCSessionDescription(),
                from: offerCarrier.from)
            print("Received Offer")
        } else if let answerCarrier = try? JSONDecoder().decode(
            Carrier<AnswerSignalingMessage.AnswerContainer>.self,
            from: data) {
            delegate?.spreedClient(
                self,
                didReceiveAnswer: answerCarrier.data.answer.toRTCSessionDescription(),
                from: answerCarrier.from)
            print("Received Answer")
        } else if let candidateCarrier = try? JSONDecoder().decode(
            Carrier<CandidateSignalingMessage.CandidateContainer>.self,
            from: data) {
            delegate?.spreedClient(
                self,
                didReceiveCandidate: candidateCarrier.data.candidate.toRtcCandidate(),
                from: candidateCarrier.from)
            print("Received Candidate")
        } else if let leftCarrier = try? JSONDecoder().decode(
        Carrier<LeftSignalingMessage>.self,
        from: data) {
            delegate?.spreedClient(self, userDidLeave: leftCarrier.data.id)
        }
    }

    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("Websocket data")
    }
}

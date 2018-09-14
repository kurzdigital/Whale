//
//  SessionDescription.swift
//  WAL
//
//  Created by Christian Braun on 23.08.18.
//

import Foundation
import WebRTC

enum SdpType: String, Codable {
    case offer
    case answer
    case pranswer
}
struct SessionDescription: Codable {
    let type: SdpType
    let sdp: String

    init(from rtcSessionDescription: RTCSessionDescription) {
        self.sdp = rtcSessionDescription.sdp

        switch rtcSessionDescription.type {
        case .offer:
            self.type = .offer
        case .prAnswer:
            self.type = .pranswer
        case .answer:
            self.type = .answer
        }
    }
    func toRTCSessionDescription() -> RTCSessionDescription {
        let rtcSdpType: RTCSdpType

        switch type {
        case .offer:
            rtcSdpType = .offer
        case .answer:
            rtcSdpType = .answer
        case .pranswer:
            rtcSdpType = .prAnswer
        }
        return RTCSessionDescription(type: rtcSdpType, sdp: sdp)
    }
}

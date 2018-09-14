//
//  Candidate.swift
//  WAL
//
//  Created by Christian Braun on 23.08.18.
//

import Foundation
import WebRTC

struct Candidate: Codable {
    let type: String = "candidate"
    let sdpMLineIndex: Int32
    let sdpMid: String?
    let candidate: String

    init(from iceCandidate: RTCIceCandidate) {
        self.sdpMLineIndex = iceCandidate.sdpMLineIndex
        self.sdpMid = iceCandidate.sdpMid
        self.candidate = iceCandidate.sdp
    }

    func toRtcCandidate() -> RTCIceCandidate  {
        return RTCIceCandidate(sdp: candidate, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
    }
}

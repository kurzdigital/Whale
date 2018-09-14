//
//  WebRTCConnection+Config+TurnServer.swift
//  Pods-Whale
//
//  Created by Christian Braun on 21.08.18.
//

import Foundation

public extension WebRTCConnection {
    public struct Config {
        public let signalingServerUrl: String
        public let turnServer: TurnServer?
        public let stunServerUrl: String?
        public let formatConstraints: FormatConstraints?

        public init(
            signalingServerUrl: String,
            turnServer: TurnServer?,
            stunServerUrl: String?,
            formatConstraints: FormatConstraints?) {
            self.signalingServerUrl = signalingServerUrl
            self.turnServer = turnServer
            self.stunServerUrl = stunServerUrl
            self.formatConstraints = formatConstraints
        }
    }

    public struct TurnServer {
        public let url: String
        public let username: String
        public let password: String

        public init(url: String, username: String, password: String) {
            self.url = url
            self.username = username
            self.password = password
        }
    }

    public struct FormatConstraints {
        public let preferredWidth: Int32
        public let preferredHeight: Int32

        public init(preferredWidth: Int32, preferredHeight: Int32) {
            self.preferredWidth = preferredWidth
            self.preferredHeight = preferredHeight
        }
    }
}

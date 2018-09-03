//
//  Config.swift
//  Whale
//
//  Created by Christian Braun on 02.09.18.
//  Copyright © 2018 KURZ Digital Solutions GmbH & Co. KG. All rights reserved.
//

import Foundation
import WAL

struct Config {
    struct UserDefaults {
        static let itemsKey = "WhaleItems"
    }

    struct WebRTC {
        fileprivate static let formatConstraints = WebRTCConnection.FormatConstraints(
            preferredWidth: 640,
            preferredHeight: 480)
        static let config = WebRTCConnection.Config(
            signalingServerUrl: "ws://notimeforthat.org:8080/ws",
            turnServer: nil,
            stunServerUrl: nil,
            formatConstraints: formatConstraints)
    }
}

Whale
=====
![whale](/whale.png)

This is a demo application to show the synergy between WebRTC and Callkit. It does not claim to be complete or error safe in any way. Only the necessary parts of these both technologies are implemented to show a simple call demo.

## Prerequisite 

* Swift 4.1
* CocoaPods
* Xcode 9
* Set privacy notice for camera and microphone
* Docker for the signaling server
* coturn or any other turn server

## Signaling and Turn server
We suggest using the [Spreed Signaling Server](https://github.com/strukturag/spreed-webrtc) and the [coturn turn server](https://github.com/coturn/coturn).

For a more in depth usage description please see the README of our [WebRTC Abstraction Layer lib](https://github.com/kurzdigital/WAL).

## Config

To configure the app with our own servers and credentials please take a look into the `Config.swift` file.

```
static let config = WebRTCConnection.Config(
            signalingServerUrl: "ws://signaling.org:8080/ws",
            turnServer: turnServer,
            stunServerUrl: nil,
            formatConstraints: formatConstraints)
```

## Usage
To make two devices connect you have to ensure that at least the signaling server is running. If the two devices are in different networks you also have to run a stun or turn server.
Make sure to start the app onto the two devices time-shifted. When the connect button is enabled you are ready to make a call.
All CallKit related code is placed within the `CallManager.swift` file.
Almost all WebRTC connection related code comes from our [WAL lib](https://github.com/kurzdigital/WAL).

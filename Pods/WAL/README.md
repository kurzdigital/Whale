WebRTC Abstraction Layer (WAL)
==============================

This lib is currently only for demo purposes and presents the basic mechanics of a WebRTC connection for iOS.
The usage is restricted to video calls. There is no api to create an audio only call yet.
Keep in mind that there is no security or authorization provided!

## Installation with CocoaPods

Add the following to your Podfile

```
pod 'WAL'
```

Run `pod install`

## Prerequisite 

* Swift 4.1
* Xcode 9
* Set Privacy notice for camera and microphone
* Docker for the signaling server

## Signaling Server

As you may now you will need some kind of signaling to create a WebRTC connection. 
This lib uses a signaling server called [Spreed](https://github.com/strukturag/spreed-webrtc).
Fortunately they provide a docker image for their webservice which you can start the following way:
```
docker run --rm --name my-spreed-webrtc -p 8080:8080 -p 8443:8443
```
Or create a `docker-compose.yml` file:

```
version: '3'
services:
  spreed:
    image: "spreed/webrtc"
    ports:
      - "8080:8080"
      - "8443:8443"
```
Then you can just run `docker-compose up`

## Usage

```
import WebRTC
import WAL
```
To create a connection:

```
let currentConnection = WebRTCConnection(with: WebRTConnection.Config(...), delegate: self)
// Join room on signaling server
currentConnection.join(roomName: "Whale")
```

Implement the WebRTCConnectionDelegate:

```
func webRTCConnection(_ sender: WebRTCConnection, didReceiveLocalCapturer localCapturer: RTCCameraVideoCapturer)
func webRTCConnection(_ sender: WebRTCConnection, didReceiveRemoteVideoTrack remoteTrack: RTCVideoTrack)
func webRTCConnection(_ sender: WebRTCConnection, didReceiveLocalAudioTrack remoteTrack: RTCAudioTrack)
func webRTCConnection(_ sender: WebRTCConnection, didReceiveRemoteAudioTrack remoteTrack: RTCAudioTrack)
func webRTCConnection(_ sender: WebRTCConnection, userDidJoin userId: String)
func webRTCConnection(_ sender: WebRTCConnection, didChange state: WebRTCConnection.State)
func didOpenDataChannel(_ sender: WebRTCConnection)
func webRTCConnection(_ sender: WebRTCConnection, didReceiveDataChannelData data: Data)
func didReceiveIncomingCall(_ sender: WebRTCConnection, from userId: String)i
```

To initiate a call:
```
currentConnection.connect(toUserId: userId)
```

To answer an incoming call:

```
currentConnection.answerIncomingCall(userId: userId)
```

To send data via data channel:
```
currentConnection.send(data: data)
```

## Support

If you find errors or have any suggestions please let us know via an issue or a pull request.
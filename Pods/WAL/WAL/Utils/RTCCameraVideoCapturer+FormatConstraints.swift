//
//  RTCCameraVideoCapturer+FormatConstraints.swift
//  WAL
//
//  Created by Christian Braun on 30.08.18.
//

import Foundation
import WebRTC

extension RTCCameraVideoCapturer {
    static func format(
        for device: AVCaptureDevice,
        constraints: WebRTCConnection.FormatConstraints?) -> AVCaptureDevice.Format {
        var selectedFormat = device.activeFormat
        var currentDiff = Int32.max

        guard let constraints = constraints else{
            return selectedFormat
        }

        for format in device.formats {
            let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)

            let diff = abs(constraints.preferredWidth - dimension.width)
                + abs(constraints.preferredHeight - dimension.height)

            if diff < currentDiff {
                selectedFormat = format
                currentDiff = diff
            }
        }

        return selectedFormat
    }

    static func fps(for format: AVCaptureDevice.Format) -> Int {
        let frameRateLimit = 30.0
        var maxSupportedFramerate = 0.0;

        for fpsRange in format.videoSupportedFrameRateRanges {
            maxSupportedFramerate = max(maxSupportedFramerate, fpsRange.maxFrameRate)
        }

        return Int(min(maxSupportedFramerate, frameRateLimit))
    }
}

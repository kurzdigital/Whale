//
//  SoundManager.swift
//  Whale
//
//  Created by Christian Braun on 02.09.18.
//  Copyright © 2018 KURZ Digital Solutions GmbH & Co. KG. All rights reserved.
//

import AVFoundation

struct SoundManager {
    static func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try session.setMode(AVAudioSessionModeVideoChat)
            try session.setPreferredIOBufferDuration(0.005)
            try session.setPreferredSampleRate(4_410)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    static func routeAudioToSpeaker() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
    }
}

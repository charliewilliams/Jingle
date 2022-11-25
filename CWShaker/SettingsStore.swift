//
//  SettingsStore.swift
//  Jingle-SwiftUI
//
//  Created by Charlie Williams on 07/01/2022.
//

import Foundation

private let keepPlayingAudioInBackgroundKey = "keepPlayingAudioInBackground"

class SettingsStore: ObservableObject {
    
    @Published var keepPlayingAudioInBackground: Bool = UserDefaults.standard.bool(forKey: keepPlayingAudioInBackgroundKey) {
        didSet {
            UserDefaults.standard.set(keepPlayingAudioInBackground, forKey: keepPlayingAudioInBackgroundKey)
        }
    }
}

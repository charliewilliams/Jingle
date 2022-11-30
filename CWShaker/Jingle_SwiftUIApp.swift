//
//  Jingle_SwiftUIApp.swift
//  Jingle-SwiftUI
//
//  Created by Charlie Williams on 19/12/2021.
//

import SwiftUI
import AVFoundation

private let kPlayAudioInBackgroundKey = "kPlayAudioInBackgroundKey"

@main
struct Jingle_SwiftUIApp: App {
    
    @Environment(\.scenePhase) var scenePhase
    
    let audio = CWAudioHandler.shared()
//    let motion = Motion.shared
    
    let motion = MotionTracker()
    
    init() {
        
        UserDefaults.standard.register(defaults: ["kPlayAudioInBackgroundKey": true])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
                
            case .background:
                if !SettingsStore().keepPlayingAudioInBackground {
//                    audio.stop()
                    motion.stop()
                }
                
            case .inactive:
//                audio.stop()
//                motion.stop()
                break
                
            case .active:
                audio.start()
                motion.start()
                
            @unknown default:
                fatalError("New thing here")
            }
        }
    }
}

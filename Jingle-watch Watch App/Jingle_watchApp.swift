//
//  Jingle_watchApp.swift
//  Jingle-watch Watch App
//
//  Created by Charlie Williams on 02/12/2022.
//  Copyright © 2022 Charlie Williams. All rights reserved.
//

import SwiftUI

@main
struct Jingle_watch_Watch_AppApp: App {
    
    @Environment(\.scenePhase) var scenePhase
    
    let audio = CWAudioHandler.shared()
    let motion = MotionTracker()
    
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

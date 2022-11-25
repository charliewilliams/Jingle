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
    
    let audio = CWAudioHandler.shared
    let motion = Motion.shared
    
    init() {
        
        UserDefaults.standard.register(defaults: ["kPlayAudioInBackgroundKey": true])
        
        do {
            Settings.bufferLength = .short
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(Settings.bufferLength.duration)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord,
                                                            options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let err {
            print(err)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
                
            case .background:
                audio.didBackground()
                
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

//
//  Motion.swift
//  MusicCushion
//
//  Created by Charlie Williams on 19/10/2021.
//

import CoreMotion
import UIKit

class Motion {

    private var onMotion: [((Double)->Void)] = []
    
    private let manager = CMMotionManager()
    
    private let filter = HighpassFilter(sampleRate: 1/60.0, cutoff: 5, adaptive: true)
    
    private lazy var queue: OperationQueue = {
        let q = OperationQueue()
        q.qualityOfService = .userInteractive
        return q
    }()
    
    static let shared = Motion()
    
    private init() {
        
        if !SettingsStore().keepPlayingAudioInBackground {
            NotificationCenter.default.addObserver(self, selector: #selector(stop), name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(start), name: UIApplication.willEnterForegroundNotification, object: nil)
        }
        
        start()
    }
    
    @objc func start() {

        manager.deviceMotionUpdateInterval = 1/60.0
        
        manager.startDeviceMotionUpdates(to: queue) { motion, error in
            
            guard let motion = motion else {
                return
            }
            
            self.gotMotion(motion)
        }
    }
    
    @objc func stop() {
        
        manager.stopDeviceMotionUpdates()
    }
    
    @objc func didBackground() {
        
        if !SettingsStore().keepPlayingAudioInBackground {
            stop()
        }
    }
    
    func addOnMotion(_ block: @escaping (Double)->Void) {
        onMotion.append(block)
    }
}

private extension Motion {
    
    func magnitude(from attitude: CMAttitude) -> Double {
        sqrt(pow(attitude.roll, 2) + pow(attitude.yaw, 2) + pow(attitude.pitch, 2))
    }
    
    func magnitude(from acceleration: CMAcceleration) -> Double {
        sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
    }
    
    func gotMotion(_ motion: CMDeviceMotion) {
        
        filter.add(acceleration: motion.userAcceleration)
        
        let mag = magnitude(from: CMAcceleration(x: filter.lastX, y: filter.lastY, z: filter.lastZ))
        onMotion.forEach { $0(mag) }
    }
}

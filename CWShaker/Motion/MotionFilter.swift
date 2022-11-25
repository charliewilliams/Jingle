//
//  MotionFilter.swift
//  Jingle
//
//  Created by Charlie Williams on 07/01/2022.
//

import CoreMotion

// Implementation of the basic filter. All it does is mirror input to output.

class AccelerometerFilter {

    var x: Double = 0
    var y: Double = 0
    var z: Double = 0
    var adaptive: Bool
    
    let rate: Double
    let filterConstant: Double
    
    var name: String {
        "Base Class"
    }
    
    init(sampleRate: Double, cutoff: Double, adaptive: Bool) {
        
        rate = sampleRate
        self.adaptive = adaptive
        
        let dt = 1.0 / rate
        let RC = 1.0 / cutoff
        filterConstant = dt / (dt + RC)
    }

    func add(acceleration a: CMAcceleration) {
        x = a.x
        y = a.y
        z = a.z
    }
}

let kAccelerometerMinStep               = 0.02
let kAccelerometerNoiseAttenuation      = 3.0

func norm(_ x: Double, _ y: Double, _ z: Double) -> Double {
    sqrt(x * x + y * y + z * z)
}

func clamp(_ v: Double, _ min: Double, _ max: Double) -> Double {
    if v > max {
        return max
    }
    else if v < min {
        return min
    }
    else {
        return v
    }
}

// See http://en.wikipedia.org/wiki/Low-pass_filter for details low pass filtering
class LowpassFilter: AccelerometerFilter {
    
    override var name: String {
        adaptive ? "Adaptive Lowpass Filter" : "Lowpass Filter"
    }

    override func add(acceleration a: CMAcceleration) {
        
        var alpha = filterConstant
        
        if adaptive {
            let d = clamp(abs(norm(x, y, z) - norm(a.x, a.y, a.z)) / kAccelerometerMinStep - 1.0, 0.0, 1.0)
            alpha = (1.0 - d) * filterConstant / kAccelerometerNoiseAttenuation + d * filterConstant;
        }
        
        x = a.x * alpha + x * (1.0 - alpha)
        y = a.y * alpha + y * (1.0 - alpha)
        z = a.z * alpha + z * (1.0 - alpha)
    }
}

// See http://en.wikipedia.org/wiki/High-pass_filter for details on high pass filtering
class HighpassFilter: AccelerometerFilter {
    
    var lastX: Double = 0
    var lastY: Double = 0
    var lastZ: Double = 0
    
    override var name: String {
        adaptive ? "Adaptive Highpass Filter" : "Highpass Filter"
    }
    
    override func add(acceleration a: CMAcceleration) {
        
        var alpha = filterConstant
        
        if adaptive {
            let d = clamp(abs(norm(x, y, z) - norm(a.x, a.y, a.z)) / kAccelerometerMinStep - 1.0, 0.0, 1.0)
            alpha = d * filterConstant / kAccelerometerNoiseAttenuation + (1.0 - d) * filterConstant
        }
        
        x = alpha * (x + a.x - lastX)
        y = alpha * (y + a.y - lastY)
        z = alpha * (z + a.z - lastZ)
        
        lastX = a.x
        lastY = a.y
        lastZ = a.z
    }
}

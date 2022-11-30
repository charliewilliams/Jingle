//
//  Instrument.swift
//  Jingle-SwiftUI
//
//  Created by Charlie Williams on 05/01/2022.
//

import SwiftUI

enum InstrumentType: String, CaseIterable {
    case jingle = "Sleigh Bells"
    case maracas
    case tambourine
    case shaker
    case spaceWater = "Space Water"
    case spaceIce = "Space Ice Cubes"
}

class InstrumentStore {
    
    static let shared = InstrumentStore()
    
    var instruments: [Instrument]
    
    private init() {
        
        instruments = InstrumentType.allCases.map { Instrument(type: $0) }
    }
}

struct Instrument: Identifiable {
    
    var id = UUID()
    
    let index: Int
    let image: Image
    let type: InstrumentType
    
    let inst: CWInstrument
    
    /// Don't go making these randomly
    /// Access them from the instrument store above
    fileprivate init(type: InstrumentType) {
        
        self.type = type
        self.index = InstrumentType.allCases.firstIndex(of: type)!
        
        self.inst = CWInstrumentFactory.instrument(at: index)
        
        switch type {
        case .jingle:
            image = Image("Sleigh_Bells")
            
        case .maracas:
            image = Image("Maracas")
            
        case .tambourine:
            image = Image("Tambourine")
            
        case .shaker:
            image = Image("Egg_Shaker")
            
        case .spaceWater:
            image = Image("Space_Water")
            
        case .spaceIce:
            image = Image("Space_Water2")
        }
    }
    
    func displayName() -> String {
        type.rawValue.capitalized
    }
    
    func motion(magnitude: Double) {
        
        if magnitude > 0.02 {
//            inst.trigger(note: 64, velocity: UInt8(min(127, magnitude * 127)))
            
//            inst.trigger(type: name, amplitude: min(1, magnitude))
        }
    }
}

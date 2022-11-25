//
//  Instrument.swift
//  Jingle-SwiftUI
//
//  Created by Charlie Williams on 05/01/2022.
//

import AudioKit
import STKAudioKit
import SwiftUI

enum InstrumentName: String, CaseIterable {
    case jingle = "Sleigh Bells"
    case maracas
    case tambourine
    case shaker
    case spaceWater = "Space Water"
    case spaceIce = "Space Ice Cubes"
}

struct Instrument: Identifiable {
    
    var id: ObjectIdentifier { ObjectIdentifier(name as NSString) }
    
    let name: String
    let index: Int
    let image: Image
    let inst: STKAudioKit.Shaker
    let type: ShakerType
    
    init(name: InstrumentName) {
        
        self.name = name.rawValue.capitalized
        self.index = InstrumentName.allCases.firstIndex(of: name)!
        self.inst = STKAudioKit.Shaker()
        
        switch name {
        case .jingle:
            image = Image("Sleigh_Bells")
            type = .sleighBells
            
        case .maracas:
            image = Image("Maracas")
            type = .maraca
            
        case .tambourine:
            image = Image("Tambourine")
            type = .tambourine
            
        case .shaker:
            image = Image("Egg_Shaker")
            type = .sandPaper
            
        case .spaceWater:
            image = Image("Space_Water")
            type = .waterDrops
            
        case .spaceIce:
            image = Image("Space_Water2")
            type = .bambooChimes
        }
        
        inst.start()
//        inst.play()
        
//        inst.scheduleMIDIEvent(event: MIDIEvent(programChange: <#T##MIDIByte#>, channel: <#T##MIDIChannel#>))
    }
    
    func motion(magnitude: Double) {
        
        if magnitude > 0.02 {
//            inst.trigger(note: 64, velocity: UInt8(min(127, magnitude * 127)))
            
            inst.trigger(type: type, amplitude: min(1, magnitude))
        }
    }
}

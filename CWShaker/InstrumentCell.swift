//
//  InstrumentCell.swift
//  Jingle-SwiftUI
//
//  Created by Charlie Williams on 05/01/2022.
//

import SwiftUI

struct InstrumentCell: View {
    
    let instrument: Instrument
    
    var body: some View {
        
        ZStack {
            Image("background", bundle: nil)
                .resizable()
                .edgesIgnoringSafeArea(.all)
            VStack {
                instrument.image
                    .clipShape(Circle())
                    .shadow(radius: 5)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                
                Text(instrument.displayName())
                    .font(.title)
                    .foregroundColor(.white)
                    .bold()
            }
        }
    }
}

struct InstrumentCell_Previews: PreviewProvider {
    
    static var previews: some View {
        ZStack {
            Color.red
                .edgesIgnoringSafeArea(.all)
            InstrumentCell(instrument: InstrumentStore.shared.instruments[0])
                .frame(width: 250, height: 400, alignment: .center)
                .border(Color.white, width: 5)
                .cornerRadius(10)
        }
    }
}

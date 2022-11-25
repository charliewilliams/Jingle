//
//  ContentView.swift
//  Jingle-SwiftUI
//
//  Created by Charlie Williams on 19/12/2021.
//

import SwiftUI

fileprivate var scrollingHStackModifier = ScrollingHStackModifier(items: AudioHandler.shared.instruments.count, itemWidth: 250, itemSpacing: 30)

fileprivate var activeIndex = 0

struct ContentView: View {
    
    @ObservedObject var settingsStore = SettingsStore()
    
    let motion = Motion.shared
    
    init() {
        scrollingHStackModifier.onUpdateIndex = { index in
            activeIndex = index
        }
    }
    
    var body: some View {
        ZStack {
            Color.accentColor
                .edgesIgnoringSafeArea(.all)
            Image("background", bundle: nil)
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                Text("Jingle+")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .bold()
                Text("Shake to make sound.")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.bottom, 75)
                
                HStack(alignment: .center, spacing: 30) {
                    ForEach(AudioHandler.shared.instruments) {
                        InstrumentCell(instrument: $0)
                            .frame(width: 250, height: 400, alignment: .center)
                            .cornerRadius(10)
                            .shadow(radius: 20)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(.white, lineWidth: 4))
                    }
                }
                .modifier(scrollingHStackModifier)
            }
            
            VStack(alignment: .leading) {
                Spacer()
                
                Toggle(isOn: $settingsStore.keepPlayingAudioInBackground) {
                    Text("Keep playing sound when app is backgrounded")
                        .foregroundColor(.white)
                        .font(.footnote)
                }
                .tint(Color.blue)
                .toggleStyle(.switch)
            }
            .fixedSize(horizontal: true, vertical: false)
            
            VStack(alignment: .trailing) {
                
                HStack {
                    Spacer()
                    Button {
                        /// Open info
                        print("hi")
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .tint(.white)
                    }
                }
                Spacer()
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .onAppear {
            motion.addOnMotion { mag in
                AudioHandler.shared.instruments[activeIndex].motion(magnitude: mag)
            }
            motion.start()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

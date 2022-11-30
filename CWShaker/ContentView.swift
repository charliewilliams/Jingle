//
//  ContentView.swift
//  Jingle-SwiftUI
//
//  Created by Charlie Williams on 19/12/2021.
//

import SwiftUI

fileprivate var scrollingHStackModifier = ScrollingHStackModifier(items: InstrumentStore.shared.instruments.count, itemWidth: 250, itemSpacing: 30)

struct ContentView: View {
    
    @Environment(\.openURL) private var openURL
    @ObservedObject var settingsStore = SettingsStore()
    
    let motion = Motion.shared
    
    init() {
        scrollingHStackModifier.onUpdateIndex = { index in
            InstrumentStore.shared.selectInstrument(at: index)
        }
    }
    
    var body: some View {
        ZStack {
            
            Image("background")
                .resizable()
                .ignoresSafeArea()
            
            VStack {
                
                Button {
                    openURL(URL(string: "https://linktr.ee/larkhall")!)
                } label: {
                    Image(systemName: "questionmark.circle.fill")
                        .tint(.white)
                }
                
                Spacer()
                
                Text("Jingle+")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .bold()
                Text("Shake to make sound.")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.bottom, 75)
                
                HStack(alignment: .center, spacing: 30) {
                    ForEach(InstrumentStore.shared.instruments) { inst in
                        InstrumentCell(instrument: inst)
                            .frame(width: 250, height: 400, alignment: .center)
                            .cornerRadius(10)
                            .shadow(radius: 20)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(.white, lineWidth: 4))
                    }
                }
                .modifier(scrollingHStackModifier)

                Spacer()
                
                Toggle(isOn: $settingsStore.keepPlayingAudioInBackground) {
                    Text("Keep playing sound when app is backgrounded")
                        .foregroundColor(.white)
                        .font(.footnote)
                }
                .tint(Color.blue)
                .toggleStyle(.switch)
                .fixedSize(horizontal: true, vertical: false)
            
                Spacer()
            }
        }
        .onAppear {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                CWAudioHandler.shared().playExampleSound(for: InstrumentStore.shared.selectedInstrument.inst)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

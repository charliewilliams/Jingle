/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view showing a scrollable list of landmarks.
*/

import SwiftUI

struct CategoryRow: View {
    
    var categoryName: String
    var items: [Sound]
    
    var body: some View {
        VStack(alignment: .center) {
            Text(self.categoryName)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.leading, 15)
                .padding(.top, 5)
                .padding(.bottom, 75)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 40) {
                    ForEach(self.items) { sound in
                        CategoryItem(sound: sound)
                    }
                }
            }
            .frame(height: 185)
            .padding(.leading, 75)
        }
    }
}

struct CategoryItem: View {
    
    var sound: Sound
    
    var body: some View {
        
        VStack(alignment: .center) {
            
            sound.image
                .renderingMode(.original)
                .resizable()
                .frame(width: 160, height: 160)
                .border(.white, width: 5)
                .clipShape(Circle())
            
            Text(sound.name)
                .foregroundColor(.white)
                .font(.headline)
        }
        .padding(.leading, 15)
    }
}

struct CategoryRow_Previews: PreviewProvider {
    
    static var previews: some View {
        
        CategoryRow(
            categoryName: "Sounds",
            items: [Sound.jingle, Sound.iceCubes]
        )
    }
}

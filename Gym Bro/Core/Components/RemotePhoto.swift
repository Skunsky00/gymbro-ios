//
//  RemotePhoto.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation
import SwiftUI

struct RemotePhoto: View {
    let urlString: String

    var body: some View {
        Color.clear
            .aspectRatio(3 / 4, contentMode: .fit)
            .background(Color.primary.opacity(0.06))
            .overlay {
                AsyncImage(url: URL(string: urlString)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        ProgressView()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

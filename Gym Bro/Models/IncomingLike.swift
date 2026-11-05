//
//  IncomingLike.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/30/26.
//

import Foundation


struct IncomingLike: Identifiable {
    let senderID: String
    let mode: MatchMode
    let user: AppUser
    let photoURL: String?
    let comment: String?
    let createdAt: Date
    // The same person can send a train like and a date like.
    var id: String { "\(senderID)_\(mode.rawValue)" }
}

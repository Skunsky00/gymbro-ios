//
//  LikesStatus.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/30/26.
//

import Foundation

struct LikeStatus {
    let isPremium: Bool
    let limit: Int?
    let remaining: Int?        // nil means unlimited (premium)
}

struct ReceivedLike {
    let fromID: String
    let mode: MatchMode
    let photoURL: String?
    let comment: String?
    let createdAt: Date
}

struct ReceivedLikesResponse {
    let isPremium: Bool
    let trainCount: Int
    let dateCount: Int
    let likes: [ReceivedLike]  // empty for free users
}

struct LikeResult {
    let matched: Bool
    let remaining: Int?
}

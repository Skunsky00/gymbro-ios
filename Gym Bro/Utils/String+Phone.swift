//
//  String+Phone.swift
//  Gym Bro
//
//  Created by Jacob Johnson on 10/23/26.
//

import Foundation


extension String {
    var e164US: String {
        "+1" + filter(\.isNumber)
    }
    var isValidUSPhone: Bool {
        filter(\.isNumber).count == 10
    }
}

extension String {
    var formattedUSPhone: String {
        let digits = String(filter(\.isNumber).prefix(10))
        var result = ""
        for (i, ch) in digits.enumerated() {
            if i == 0 { result += "(" }
            if i == 3 { result += ") " }
            if i == 6 { result += "-" }
            result.append(ch)
        }
        return result
    }
}

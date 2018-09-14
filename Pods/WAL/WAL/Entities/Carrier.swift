//
//  Carrier.swift
//  WAL
//
//  Created by Christian Braun on 22.08.18.
//

import Foundation

struct Carrier <A: Codable>: Codable {
    let data: A
    let from: String

    enum CodingKeys: String, CodingKey {
        case data = "Data"
        case from = "From"
    }
}

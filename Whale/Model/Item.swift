//
//  Item.swift
//  Whale
//
//  Created by Christian Braun on 02.09.18.
//  Copyright © 2018 KURZ Digital Solutions GmbH & Co. KG. All rights reserved.
//

import Foundation

struct Item: Codable {
    let value: String
}

extension Item {
    static func items() -> [Item] {
        guard let data = UserDefaults.standard.data(forKey: Config.UserDefaults.itemsKey) else {
            return [Item]()
        }
        guard let items = try? JSONDecoder().decode([Item].self, from: data) else {
            fatalError("Unable to read items from user defaults")
        }

        return items
    }

    static func save(_ items: [Item]) {
        guard let data =  try? JSONEncoder().encode(items) else {
            fatalError("Unable to save items to user defaults")
        }

        UserDefaults.standard.set(data, forKey: Config.UserDefaults.itemsKey)
    }
}

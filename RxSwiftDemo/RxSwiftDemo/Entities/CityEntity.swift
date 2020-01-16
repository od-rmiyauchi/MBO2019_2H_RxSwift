//
//  CityEntity.swift
//  RxSwiftDemo
//
//  Created by 宮内 龍之介 on 2019/12/05.
//  Copyright © 2019 宮内 龍之介. All rights reserved.
//

import Foundation

struct CityEntity: Codable {
    let id: String
    let name: String
    let kana: String
    let pref: String
    
    func containWord(_ word: String) -> Bool{
        let lowercased = word.lowercased()
        return
            name.lowercased().contains(lowercased) ||
            kana.lowercased().contains(lowercased) ||
            pref.lowercased().contains(lowercased)
    }
}

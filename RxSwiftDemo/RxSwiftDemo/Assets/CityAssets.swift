//
//  CityAssets.swift
//  RxSwiftDemo
//
//  Created by 宮内 龍之介 on 2019/12/05.
//  Copyright © 2019 宮内 龍之介. All rights reserved.
//

import Foundation
import RxSwift

enum CityError: Error {
    case notFound
    case parseJson
}

class CityAssets {
    func getCity(disposeBag: DisposeBag,
                 onSuccess: @escaping ([CityEntity]) -> Void,
                 onError: @escaping (Error) -> Void) {
        guard let asset = NSDataAsset(name: "cities-json") else {
            onError(CityError.notFound)
            return
        }
        
        let jsonData = String(data: asset.data, encoding: .utf8)?.data(using: .utf8)
        let decoder = JSONDecoder()
        
        if let jsonData = jsonData,
            let CityEntities = try? decoder.decode([CityEntity].self, from: jsonData) {
            onSuccess(CityEntities)
        } else {
            onError(CityError.parseJson)
        }
    }
}

//
//  Entity.swift
//  RxSwiftDemo
//
//  Created by 宮内 龍之介 on 2019/12/03.
//  Copyright © 2019 宮内 龍之介. All rights reserved.
//

import Foundation

struct WeatherEntity: Codable {
    let publicTime: String
    let title: String
    let description: Description
    let link: String
    let forecasts: [Forecast]
    let location: Location
}

extension WeatherEntity {
    struct Description: Codable {
        let text: String
        let publicTime: String
    }
    
    struct Forecast: Codable {
        let dateLabel: String
        let telop: String
        let date: String
        let temperature: Temperture
    }

    struct Temperture: Codable {
        let min: TempertureValue?
        let max: TempertureValue?
    }
    
    struct Location: Codable {
        let city: String
        let area: String
        let prefecture: String
    }
}

extension WeatherEntity.Temperture {
    struct TempertureValue: Codable {
        let celsius: String
        let fahrenheit: String
    }
}

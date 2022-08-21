//
//  WeatherDataModel.swift
//  ClosingTime
//
//  Created by Rik Roy on 8/19/22.
//

import Foundation
import SwiftUI
struct WeatherDataModel: Codable {
    let queryCost: Int
    let days: [CurrentConditions]
}

struct CurrentConditions: Codable {
    let humidity, dew: Double
    let precip: Double
    let windspeed: Double
    let tempmax, tempmin: Double
}


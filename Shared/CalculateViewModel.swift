//
//  CalculateViewModel.swift
//  ClosingTime
//
//  Created by Rik Roy on 8/17/22.
//

import Foundation
import Combine
import SwiftUI

class CalculateViewModel: ObservableObject {
    
    init(max: Double, min: Double, dew: Double, humidity: Double, ws: Double, precip: Double) {
        fetchEvents(intMax: max, intMin: min, intDew: dew, intHumidity: humidity, intWS: ws, intPrecip: precip)
    }
    
    var preds = [CalculateModel]() {
        didSet {
            didChange.send(self)
        }
    }
    
    func fetchEvents(intMax: Double, intMin: Double, intDew: Double, intHumidity: Double, intWS: Double, intPrecip: Double) {
        CalculateCall().getPred(max: intMax, min: intMin, dew: intDew, humidity: intHumidity, ws: intWS, precip: intPrecip) {
            self.preds = $0
        }
    }
    let didChange = PassthroughSubject<CalculateViewModel, Never>()
    
}

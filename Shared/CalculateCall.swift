//
//  CalculateCall.swift
//  ClosingTime
//
//  Created by Rik Roy on 8/17/22.
//

import Foundation
import Combine


class CalculateCall {
    
    func getPred(max: Double, min: Double, dew: Double, humidity: Double, ws: Double, precip: Double, completion: @escaping ([CalculateModel]) -> ()) {
        guard let url = URL(string: "143.215.50.174:900/getData/" + String(max) + "/" + String(min) + "/" + String(dew) + "/" + String(humidity) + "/" + String(ws) + "/" + String(precip))
        else {
            fatalError("URL is not correct!")
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            
            let preds = try! JSONDecoder().decode([CalculateModel].self, from: data!)
            
            DispatchQueue.main.async {
                completion(preds)
            }
            }.resume()
    }
}
 

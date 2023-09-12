//
//  ContentView.swift
//  Shared
//
//  Created by Rik Roy on 7/8/22.
//

import SwiftUI
import CoreLocationUI
import CoreLocation
import Combine

struct ContentView: View {
    
    private enum Field: Int, CaseIterable {
        case maxtemp, mintemp, dew, humidity, ws, precip
    }
    
    @StateObject var deviceLocationService = DeviceLocationService.shared

    @State var tokens: Set<AnyCancellable> = []
    @State var coordinates: (lat: Double, lon: Double) = (0, 0)
    
    @State var max: String = "";
    @State var min: String = "";
    @State var dew: String = "";
    @State private var humidity: String = "";
    @State private var ws: String = "";
    @State private var precip: String = "";
    
    @State private var showingAlert = false;
    @State private var showingConfirmation = false;
    @State private var errorMessage = "";
        
    @FocusState private var focusedField: Field?
    
    @State private var prediction: String = "    "
    let locationManager = CLLocationManager()
    
    var lastLocation: CLLocation? = nil
    
    var forestGreen = Color(red:16/255, green:181/255, blue:104/255)
    
    var red = Color(red:255/255, green:135/255, blue:135/255)

    
var body: some View {
        VStack {
            
            Spacer().frame(height: 10)
            
            Text("Is School Closed Today?")
                .padding(10).foregroundColor(Color.white).font(.custom("Avenir", size: 40))
            
            ZStack {
                VStack {
                    Button{
                        let alert = UIAlertController(title: "Would you like to import today's weather data?", message: "Enter either your zipcode or city", preferredStyle: .alert)
                        
                        alert.addTextField{ (textField) in
                            textField.placeholder = "Enter zip code"
                            textField.keyboardType = UIKeyboardType.decimalPad
                        }
                        
                        alert.addTextField{ (textField) in
                            textField.placeholder = "Enter city"
                        }
                        
                        
                        
                        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {action in
                            Task {
                                guard let textFields = alert.textFields else { return }
                                    
                                guard let zipcode = textFields[0].text else { return
                                }
                                
                                guard let city = textFields[1].text else { return
                                }
                                
                                var locationToUse = "";
                                
                                if(zipcode == "") {
                                    if(city == "") {
                                        print("enter something u bozo")
                                    } else {
                                        locationToUse = city;
                                    }
                                } else {
                                    locationToUse = zipcode
                                    if(!(NSPredicate(format: "SELF MATCHES %@", "^\\d{5}(?:[-\\s]?\\d{4})?$") .evaluate(with: zipcode.uppercased()))) {
                                        let zipAlert = UIAlertController(title: "Invalid zipcode", message: "Please enter a valid zipcode", preferredStyle: .alert)
                                        zipAlert.addAction(UIAlertAction(title: "Got it!", style: .default))
                                        let scenes = UIApplication.shared.connectedScenes
                                        let windowScene = scenes.first as? UIWindowScene
                                        let window = windowScene?.windows.first!.rootViewController!
                                        
                                        window!.present(zipAlert, animated: true)
                                        return
                                    }
                                }
                                

                                
                                        
    

                                    let (data, _) = try await URLSession.shared.data(from: URL(string:"https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/" + locationToUse + "?unitGroup=metric&key=PTVHZDB7WWGNQKMF8RGWW8X3U&contentType=json")!)
                                    
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        let decodedResponse = try? JSONDecoder().decode(WeatherDataModel.self, from: data)
                                        if(decodedResponse == nil) {
                                            let networkAlert = UIAlertController(title: "Network Error", message: "Could not connect to network", preferredStyle: .alert)
                                            networkAlert.addAction(UIAlertAction(title: "OK", style: .default))
                                            let scenes = UIApplication.shared.connectedScenes
                                            let windowScene = scenes.first as? UIWindowScene
                                            let window = windowScene?.windows.first!.rootViewController!
                                            
                                            window!.present(networkAlert, animated: true)
                                            return
                                        }
                                        var intMax = (decodedResponse?.days[0].tempmax)!
                                        intMax = intMax * (9/5) + 32
                                        max = String(round(intMax * 10)/10)
                                        
                                        var intMin = (decodedResponse?.days[0].tempmin)!
                                        intMin = intMin * (9/5) + 32
                                        min = String(round(intMin * 10)/10)
                                    
                                        var intDew = (decodedResponse?.days[0].dew)!
                                        intDew = intDew * (9/5) + 32
                                        dew = String(round(intDew * 10)/10)
                                    
                                        var intHumidity = (decodedResponse?.days[0].humidity)!
                                        humidity = String(round(intHumidity * 10)/10)
                                    
                                        var intPrecip = (decodedResponse?.days[0].precip)!
                                        precip = String(round(intPrecip * 10)/10)
                                    
                                        var intWs = (decodedResponse?.days[0].windspeed)!
                                        ws = String(round((intWs/1.609) * 10)/10)
                                    

                                    }
                                    
                                }
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Use My Current Location", style: .default, handler: { action in
                            Task {
                                let (data, _) = try await URLSession.shared.data(from: URL(string:"https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/" + String(coordinates.lat) + "," + String(coordinates.lon) + "?unitGroup=metric&key=PTVHZDB7WWGNQKMF8RGWW8X3U&contentType=json")!)
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    let decodedResponse = try? JSONDecoder().decode(WeatherDataModel.self, from: data)
                                    if(decodedResponse == nil) {
                                        let networkAlert = UIAlertController(title: "Network Error", message: "Could not connect to network", preferredStyle: .alert)
                                        networkAlert.addAction(UIAlertAction(title: "OK", style: .default))
                                        let scenes = UIApplication.shared.connectedScenes
                                        let windowScene = scenes.first as? UIWindowScene
                                        let window = windowScene?.windows.first!.rootViewController!
                                        
                                        window!.present(networkAlert, animated: true)
                                        return
                                    }

                                
                                var intMax = (decodedResponse?.days[0].tempmax)!
                                intMax = intMax * (9/5) + 32
                                max = String(round(intMax * 10)/10)
                                
                                var intMin = (decodedResponse?.days[0].tempmin)!
                                intMin = intMin * (9/5) + 32
                                min = String(round(intMin * 10)/10)
                            
                                var intDew = (decodedResponse?.days[0].dew)!
                                intDew = intDew * (9/5) + 32
                                dew = String(round(intDew * 10)/10)
                            
                                var intHumidity = (decodedResponse?.days[0].humidity)!
                                humidity = String(round(intHumidity * 10)/10)
                            
                                var intPrecip = (decodedResponse?.days[0].precip)!
                                precip = String(round(intPrecip * 10)/10)
                            
                                var intWs = (decodedResponse?.days[0].windspeed)!
                                ws = String(round((intWs/1.609) * 10)/10)

                                }
                                
                            }
                        }))
                        
                        
                        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                        
                        let scenes = UIApplication.shared.connectedScenes
                        let windowScene = scenes.first as? UIWindowScene
                        let window = windowScene?.windows.first!.rootViewController!
                        
                        window!.present(alert, animated: true)
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .resizable()
                            .foregroundColor(Color.black)
                            .frame(width: 30, height: 37)
                            
                    }
                    
                }.frame(width: 250, height: 400, alignment: .topTrailing)
                    .zIndex(1)
                

                
                TabView {
                    ZStack {
                        Color.orange
                        
                        VStack {
                            Text("Enter Max and Min Temperature (°F)").font(.custom("Avenir", size: 30))
                            
                            Spacer().frame(height: 20)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white)
                                    .frame(height:40)
                                    .frame(width: 300)

                                    
                                TextField("Max Temp", text: $max) .font(.custom("Avenir", size: 15)).keyboardType(.numbersAndPunctuation)
                                    .frame(width: 280).focused($focusedField, equals: .maxtemp)

                            }
                            
                            Spacer().frame(height: 20)

                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white)
                                    .frame(height:40)
                                    .frame(width: 300)

                                    
                                    TextField("Min Temp", text: $min).font(.custom("Avenir", size: 15)).keyboardType(.numbersAndPunctuation)
                                    .frame(width: 280).focused($focusedField, equals: .mintemp)

                            }
                        }.toolbar {
                            ToolbarItem(placement: .keyboard) {
                                Button("Done") {
                                    focusedField = nil
                                }
                            }
                        }
                        

                    }
                    
                    ZStack {
                        Color.purple
                        
                        VStack {
                            Text("Enter Dew Point (°F) and Humidity").font(.custom("Avenir", size: 30))
                            
                            Spacer().frame(height: 50)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white)
                                    .frame(height:40)
                                    .frame(width: 300)

                                    
                                    TextField("Dew Point", text: $dew).font(.custom("Avenir", size: 15)).keyboardType(.numbersAndPunctuation)
                                        .frame(width: 280).focused($focusedField, equals: .dew)

                            }
                            
                            Spacer().frame(height: 20)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white)
                                    .frame(height:40)
                                    .frame(width: 300)

                                    
                                    TextField("Humidity", text: $humidity).font(.custom("Avenir", size: 15)).keyboardType(.decimalPad)
                                        .frame(width: 280).focused($focusedField, equals: .humidity)
                            

                            }
                        }.toolbar {
                            ToolbarItem(placement: .keyboard) {
                                Button("Done") {
                                    focusedField = nil
                                }
                            }
                        }
                        

                    }
                
                
                    ZStack {
                        red
                        
                        VStack {
                            Text("Enter Wind Speed (mph)").font(.custom("Avenir", size: 30))
                            
                            Spacer().frame(height: 50)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white)
                                    .frame(height:40)
                                    .frame(width: 300)

                                    
                                    TextField("Wind Speed", text: $ws).font(.custom("Avenir", size: 15)).keyboardType(.decimalPad)
                                        .frame(width: 280).focused($focusedField, equals: .ws)

                            }
                        }.toolbar {
                            ToolbarItem(placement: .keyboard) {
                                Button("Done") {
                                    focusedField = nil
                                }
                            }
                        }
                        

                    }
            
                    
                
                    

                    
                    
                    ZStack {
                        Color.teal
                        
                        VStack {
                            Text("Enter Precipitation (inches)").font(.custom("Avenir", size: 30)).padding(10)
                            
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white)
                                    .frame(height:40)
                                    .frame(width: 300)

                                    
                                    TextField("Precipitation", text: $precip).font(.custom("Avenir", size: 15)).keyboardType(.decimalPad)
                                        .frame(width: 280).focused($focusedField, equals: .precip)

                            }

                        }.toolbar {
                            ToolbarItem(placement: .keyboard) {
                                Button("Done") {
                                    focusedField = nil
                                }
                            }
                        }
                        

                    }

                    
                    ZStack {
                        forestGreen
                        VStack {
                            Text("Click Calculate for Result!").font(.custom("Avenir", size: 35))
                            
                            Spacer().frame(height: 20)
                            
                            Text("This will give you the likelihood that school will be open.").font(.custom("Avenir", size: 19))
                            
                            Spacer().frame(height: 50)
                        

                            Text(String(prediction) + " %").font(.custom("Avenir", size: 25)).padding().overlay(RoundedRectangle(cornerRadius: 15).stroke(.black, lineWidth: 5))
                                

                        }
                    }
                
                
                }.tabViewStyle(.page(indexDisplayMode: .automatic)).indexViewStyle(.page(backgroundDisplayMode: .never)).cornerRadius(30).padding(10)
            }
            
            
            
            
            HStack {
                Button {
                    
                    if(max != "") {
                        let intMax = Double(max) ?? 0
                        if(min != "") {
                            let intMin = Double(min) ?? 0
                            if(dew != "") {
                                let intDew = Double(dew) ?? 0
                                if(humidity != "") {
                                    let intHumidity = Double(humidity) ?? 0
                                    if(ws != "") {
                                        let intWS = Double(ws) ?? 0
                                        if(precip != "") {
                                            let intPrecip = Double(precip) ?? 0
                                            let model = CalculateViewModel(max: intMax, min: intMin, dew: intDew, humidity: intHumidity, ws: intWS, precip: intPrecip)
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                                let roundedPred = round(model.preds[0].Score * 10000) / 100
                                                prediction = String(roundedPred)
                                                
                                                print(prediction)
                                            }
                                        } else {
                                            showingAlert = true;
                                            errorMessage = "Enter precipitation"
                                        }
                                    } else {
                                        showingAlert = true;
                                        errorMessage = "Enter wind speed"
                                    }
                                } else {
                                    showingAlert = true;
                                    errorMessage = "Enter humidity"
                                }
                            } else {
                                showingAlert = true;
                                errorMessage = "Enter dew point"
                            }
                        } else {
                            showingAlert = true;
                            errorMessage = "Enter min temp"
                        }
                    } else {
                        showingAlert = true;
                        errorMessage = "Enter max temp"
                    }
                    
                    
                    
                    
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(forestGreen)
                            .frame(height:53)
                            .frame(width: 150)
                        Text("Calculate").font(.custom("Avenir", size: 25)).foregroundColor(Color.black)
                        
                    }
                }.alert(isPresented: $showingAlert) {
                    Alert(title: Text(errorMessage))
                }
                
                Button {
                    max = "";
                    min = "";
                    dew = "";
                    humidity = "";
                    ws = "";
                    precip = "";
                    
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.indigo)
                            .frame(height:53)
                            .frame(width: 150)
                        Text("Clear").font(.custom("Avenir", size: 25)).foregroundColor(Color.black)
                        
                    }
                }
            }
            
            
            
                

        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black).onAppear {
            observeCoordinateUpdates()
            observeDeniedLocationAccess()
            deviceLocationService.requestLocationUpdates()
        }

    }
    
    func observeCoordinateUpdates() {
            deviceLocationService.coordinatesPublisher
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    print("Handle \(completion) for error and finished subscription.")
                } receiveValue: { coordinates in
                    self.coordinates = (coordinates.latitude, coordinates.longitude)
                }
                .store(in: &tokens)
        }

        func observeDeniedLocationAccess() {
            deviceLocationService.deniedLocationAccessPublisher
                .receive(on: DispatchQueue.main)
                .sink {
                    print("Handle access denied event, possibly with an alert.")
                }
                .store(in: &tokens)
        }
    

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}





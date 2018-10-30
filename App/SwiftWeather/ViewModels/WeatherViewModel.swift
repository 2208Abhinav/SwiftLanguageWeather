//
//  WeatherViewModel.swift
//  SwiftWeather
//
//  Created by Jake Lin on 23/10/18.
//  Copyright © 2018 Jake Lin. All rights reserved.
//

import Foundation
import CoreLocation

private let emptyString = ""

class WeatherViewModel {
    // MARK: - Properties
    let errorMessage: LiveData<String?>
    
    let location: LiveData<String>
    let iconText: LiveData<String>
    let temperature: LiveData<String>
    let forecasts: LiveData<[ForecastViewModel]>
    
    // MARK: - Services
    private var locationService: LocationService
    private var weatherService: WeatherServiceProtocol
    
    // MARK: - init
    init() {
        errorMessage = LiveData(nil)
        
        location = LiveData(emptyString)
        iconText = LiveData(emptyString)
        temperature = LiveData(emptyString)
        forecasts = LiveData([])
        
        // Can put Dependency Injection here
        locationService = LocationService()
        weatherService = OpenWeatherMapService()
    }
    
    // MARK: - public
    func startLocationService() {
        locationService.delegate = self
        locationService.requestLocation()
    }
}

private extension WeatherViewModel {
    func update(weather: Weather) {
        errorMessage.postValue(value: nil)
        
        location.postValue(value: weather.location)
        iconText.postValue(value: weather.iconText)
        temperature.postValue(value: weather.temperature)
        
        let forecastsValue = weather.forecasts.map { forecast in
            return ForecastViewModel(forecast)
        }
        forecasts.postValue(value: forecastsValue)
    }
    
    func update(error: AppError) {
        switch error {
        case .urlError:
            errorMessage.postValue(value: "The weather service is not working.")
        case .networkRequestFailed:
            errorMessage.postValue(value: "The network appears to be down.")
        case .jsonParsingFailed:
            errorMessage.postValue(value: "We're having trouble parsing weather data.")
        case .unableToFindLocation:
            errorMessage.postValue(value: "We're having trouble getting user location.")
        }
        
        location.postValue(value: emptyString)
        iconText.postValue(value: emptyString)
        temperature.postValue(value: emptyString)
        self.forecasts.postValue(value: [])
    }
}

// MARK: LocationServiceDelegate
extension WeatherViewModel: LocationServiceDelegate {
    func locationDidUpdate(location: CLLocation) {
        weatherService.requestWeather(location: location) { (weather, error) -> Void in
            if let error = error {
                print(error)
                self.update(error: error)
                return
            }
            
            guard let weather = weather else {
                return
            }
            self.update(weather: weather)
        }
    }
    
    func locationDidFail(error: AppError) {
        self.update(error: error)
    }
}

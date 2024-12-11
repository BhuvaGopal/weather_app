//
//  ContentView.swift
//  Company_proj
//
//  Created by GOPAL BHUVA on 27/06/24.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedCityIndex = 0
    @State private var weatherData: WeatherResponse?
    @State private var showAnimation = false
    private let cities = ["Fremont","New York", "London", "Tokyo", "San Francisco", "Kyoto"]
    private let weatherService = WeatherService()
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .white], startPoint: .top, endPoint: .bottom)
            
            VStack {
                Text("Select a City:")
                    .font(.title)
                    .foregroundColor(.black)
                    .padding(.bottom, 10)
                
                Picker(selection: $selectedCityIndex, label: Text("City")) {
                    ForEach(0 ..< cities.count, id: \.self) { index in
                        Text(self.cities[index]).tag(index)
                    }
                    .foregroundColor(.black)
                }
                .foregroundColor(.black)
                .pickerStyle(MenuPickerStyle())
                .padding(.bottom, 20)
                
                if let weatherData = weatherData {
                    WeatherDetailView(weatherData: weatherData)
                        .onAppear {
                            withAnimation {
                                self.showAnimation = true
                            }
                        }
                } else {
                    Text("Select a city to see weather information.")
                        .foregroundColor(.black)
                        .padding()
                }
            }
            .frame(width: 300, height: 200)
            .onAppear {
                fetchWeather(for: cities[selectedCityIndex])
            }
            .onChange(of: selectedCityIndex) { newValue in
                fetchWeather(for: cities[newValue])
            }
        }
    }
    
    private func fetchWeather(for city: String) {
        weatherService.fetchWeather(for: city) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let weather):
                    print("Weather fetched successfully for \(city)")
                    self.weatherData = weather
                case .failure(let error):
                    print("Error fetching weather data for \(city): \(error.localizedDescription)")
                    self.weatherData = nil
                }
            }
        }
    }
}

struct WeatherDetailView: View {
    let weatherData: WeatherResponse
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Weather: \(weatherData.weather.first?.description ?? "")")
                .font(.title)
                .foregroundColor(.red)
                .padding(.bottom, 10)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : -20)
            
            if let temp = weatherData.main?.temp {
                Text("\(String(format: "%.1f", temp))°C")
                    .font(.title)
                    .foregroundColor(.pink)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? -0 : -20)
            } else {
                Text("Temperature: N/A")
                    .font(.title)
                    .foregroundColor(.pink)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? -10 : -2)
            }
            
            if let humidity = weatherData.main?.humidity {
                Text("Humidity: \(humidity)%")
                    .font(.title)
                    .foregroundColor(.pink)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? -50 : -20)
            } else {
                Text("Humidity: N/A")
                    .font(.title)
                    .foregroundColor(.pink)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? -70 : -50)
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.isVisible = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// WeatherResponse model to parse JSON response
struct WeatherResponse: Codable {
    let main: Main?
    let weather: [Weather]
}

struct Main: Codable {
    let temp: Double?
    let humidity: Int?
}

struct Weather: Codable {
    let description: String
}

// WeatherService to handle API requests
class WeatherService {
    private let apiKey = "55de0b365ad72b3f1d3a70dc0d9d1bae"
    private let baseUrl = "https://api.openweathermap.org/data/2.5/weather"
    
    func fetchWeather(for city: String, completion: @escaping (Result<WeatherResponse, Error>) -> Void) {
        let urlString = "\(baseUrl)?q=\(city)&appid=\(apiKey)&units=metric"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            // Print the data to inspect the JSON structure
            print(String(data: data, encoding: .utf8) ?? "Empty data")

            do {
                let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
                completion(.success(weatherResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

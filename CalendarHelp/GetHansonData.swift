//
//  GetHansonData.swift
//  runable
//
//  Created by robevans on 8/6/21.
//

import Foundation
import SwiftUI
import Combine


// MARK: - TrainingData
struct TrainingDataModel: Codable, Identifiable {
    let id, weeknumber: Int
    let totalWeekMiles: Int
    let day1, day2, day3, day4: Day
    let day5, day6, day0: Day
    let graphMiles: [Double]?
}

// MARK: - WeekExercise
struct Day: Codable {
    let day: String
    let dayMiles: Double
    let exercise: String
}

typealias trainingData = [TrainingDataModel]

class DownloadHansonData: ObservableObject {

    @Published var trainingdata: [TrainingDataModel] = []
    var cancellabes = Set<AnyCancellable>()

    init() {
        print("loading init")
        let defaults = UserDefaults.standard
        guard let getRunUrl = defaults.string(forKey: "userDefault-planUrl") else { return }
        print("getting ready to get data for \(getRunUrl)")

        //We need make sure we have the current week of training on launch.
        getPosts(runUrl: getRunUrl)
//        weekNumber = getCurrentWeek(totalWeeks: defaults.integer(forKey: "totalWeeks"), raceDate: userRaceDate)
    }


    func getPosts(runUrl: String) {

        guard let runUrl = URL(string: "https://api.npoint.io/60b107d904dbfb96cfe1") else { return }

        print("getPost url \(runUrl)")
        URLSession.shared.dataTaskPublisher(for: runUrl)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .tryMap { (data, response) -> Data in
                print(response)
                guard
                    let response = response as? HTTPURLResponse,
                      response.statusCode >= 200 && response.statusCode < 300 else {
                    throw URLError(.badServerResponse)
                }
                print(data)
                return data
            }
            .decode(type: [TrainingDataModel].self, decoder: JSONDecoder())
            .sink { (completion) in
            } receiveValue: { [weak self] (returnedData) in
                self?.trainingdata = returnedData
                print(returnedData)
            }
            .store(in: &cancellabes)
    }
}

/*

get current year week
get week of race
determine the week of training the user should be on
determine what


 */

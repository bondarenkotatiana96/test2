//
//  HealthKitManager.swift
//  HealthKitTestApp
//
//  Created by user on 11/19/23.
//

import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    init() {
        requestAuthorization()
    }
    
    var healthStore = HKHealthStore()
    
    var stepsToday: Int = 0
    
    func requestAuthorization() {
        let dataToRead = Set([
            HKObjectType.quantityType(forIdentifier: .stepCount)!])
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("health data is not available")
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: dataToRead) { success, failure in
            if success {
                self.fetchAllData()
            } else {
                print("error getting authorization")
            }
        }
    }
    
    func fetchAllData() {
        guard let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startDate = Calendar.current.startOfDay(for: now)
        
        let presicate = HKQuery.predicateForSamples(withStart: startDate,
                                                    end: now,
                                                    options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepCount,
                                      quantitySamplePredicate: presicate,
                                      options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to read user's steps with error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            self.stepsToday = steps
        }
        
        healthStore.execute(query)
    }
}

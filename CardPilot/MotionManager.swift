//
//  MotionManager.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import Foundation
import CoreMotion

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()
    
    init() {
        operationQueue.maxConcurrentOperationCount = 1
    }
    
    func collectIMUData() async -> Data? {
        return await withCheckedContinuation { continuation in
            // 使用标志位防止多次恢复continuation
            var hasResumed = false
            
            // 设置超时，防止continuation泄漏
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 15_000_000_000) // 15秒超时
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: nil)
                }
            }
            
            collectIMUData { data in
                timeoutTask.cancel() // 取消超时任务
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: data)
                }
            }
        }
    }
    
    func collectIMUData(completion: @escaping (Data?) -> Void) {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available")
            completion(nil)
            return
        }
        
        var imuDataPoints: [IMUDataPoint] = []
        let startTime = Date()
        let collectionDuration: TimeInterval = UserDefaults.standard.double(forKey: "imuCollectionDuration") > 0 ? 
            UserDefaults.standard.double(forKey: "imuCollectionDuration") : 5.0
        let updateInterval: TimeInterval = 0.01 // 100 Hz
        
        // 使用标志位防止多次调用completion
        var hasCompleted = false
        
        motionManager.deviceMotionUpdateInterval = updateInterval
        
        motionManager.startDeviceMotionUpdates(to: operationQueue) { [weak self] (motion, error) in
            guard let motion = motion, error == nil else {
                print("Motion update error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let currentTime = Date()
            let elapsed = currentTime.timeIntervalSince(startTime)
            
            if elapsed <= collectionDuration {
                let dataPoint = IMUDataPoint(
                    timestamp: elapsed,
                    accelerationX: motion.userAcceleration.x,
                    accelerationY: motion.userAcceleration.y,
                    accelerationZ: motion.userAcceleration.z,
                    rotationRateX: motion.rotationRate.x,
                    rotationRateY: motion.rotationRate.y,
                    rotationRateZ: motion.rotationRate.z
                )
                imuDataPoints.append(dataPoint)
            } else {
                // Stop collection after 5 seconds
                self?.motionManager.stopDeviceMotionUpdates()
                
                // 防止多次调用completion
                guard !hasCompleted else { return }
                hasCompleted = true
                
                let endTime = Date()
                let imuSession = IMUSession(
                    dataPoints: imuDataPoints,
                    startTime: startTime,
                    endTime: endTime
                )
                
                do {
                    let data = try JSONEncoder().encode(imuSession)
                    completion(data)
                } catch {
                    print("Failed to encode IMU data: \(error)")
                    completion(nil)
                }
            }
        }
        
        // Safety timeout to ensure we always call completion
        DispatchQueue.main.asyncAfter(deadline: .now() + collectionDuration + 1.0) { [weak self] in
            guard let self = self else { return }
            if self.motionManager.isDeviceMotionActive {
                self.motionManager.stopDeviceMotionUpdates()
                
                // 防止多次调用completion
                guard !hasCompleted else { return }
                hasCompleted = true
                completion(nil)
            }
        }
    }
    
    // MARK: - Additional Methods for NFCUsageTracker
    
    func isMotionAvailable() -> Bool {
        return motionManager.isDeviceMotionAvailable
    }
    
    func startMotionUpdates(handler: @escaping (CMDeviceMotion?) -> Void) {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.01 // 100 Hz
        motionManager.startDeviceMotionUpdates(to: operationQueue) { motion, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Motion update error: \(error.localizedDescription)")
                    handler(nil)
                } else {
                    handler(motion)
                }
            }
        }
    }
    
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}

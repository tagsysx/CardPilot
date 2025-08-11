//
//  LocationManager.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    // MARK: - Published Properties
    @Published var location: CLLocation?
    @Published var lastKnownLocation: CLLocation?
    @Published var locationServicesEnabled: Bool = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationUpdateActive: Bool = false
    @Published var locationAccuracy: CLLocationAccuracy = 0.0
    @Published var locationError: String?
    
    // MARK: - Private Properties
    private var locationCompletion: ((CLLocation?) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        setupLocationManager()
        
        // 检查位置服务状态
        checkLocationServicesStatus()
        
        // 在真机环境中，应用启动后自动开始位置更新（仅在非 App Intent 模式下）
        #if !targetEnvironment(simulator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if !(self?.isAppIntentMode ?? false) {
                self?.requestLocationPermission()
            }
        }
        #endif
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // 降低精度要求，提高成功率
        locationManager.distanceFilter = 10.0 // 10米距离过滤
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    private func updateLocationAccuracy() {
        let accuracySetting = UserDefaults.standard.integer(forKey: "locationAccuracy")
        switch accuracySetting {
        case 0:
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        case 1:
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        case 2:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        default:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // 默认使用较低精度
        }
    }
    
    private func checkLocationServicesStatus() {
        locationServicesEnabled = CLLocationManager.locationServicesEnabled()
        print("Location services enabled: \(locationServicesEnabled)")
        
        if !locationServicesEnabled {
            print("⚠️ Location services are disabled in system settings")
        }
    }
    
    private func requestLocationPermission() {
        print("Requesting location permission...")
        
        // 检查当前权限状态
        let currentStatus = locationManager.authorizationStatus
        print("Current authorization status: \(currentStatus.rawValue)")
        
        switch currentStatus {
        case .notDetermined:
            print("Requesting when in use authorization...")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("❌ Location permission denied or restricted")
            // 可以在这里提示用户去设置中开启权限
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location permission already granted")
            // 仅在非 App Intent 模式下启动位置更新
            if !isAppIntentMode {
                startLocationUpdates()
            } else {
                print("📱 App Intent mode: Skipping automatic location updates")
            }
        @unknown default:
            print("Unknown authorization status: \(currentStatus)")
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func requestLocation(completion: @escaping (CLLocation?) -> Void) {
        print("Requesting location...")
        
        // 在 App Intent 模式下不启动位置更新
        if shouldSkipLocationOperation(operation: "requestLocation") {
            completion(nil)
            return
        }
        
        // 检查位置服务是否开启
        guard locationServicesEnabled else {
            print("❌ Location services are disabled")
            completion(nil)
            return
        }
        
        // 检查权限状态
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("❌ Location authorization not granted: \(authorizationStatus.rawValue)")
            completion(nil)
            return
        }
        
        locationCompletion = completion
        
        // 如果已经有位置更新在运行，直接返回当前位置
        if let currentLocation = locationManager.location {
            print("✅ Using current location: \(currentLocation.coordinate)")
            completion(currentLocation)
            return
        }
        
        // 开始位置更新
        startLocationUpdates()
        
        // 设置超时
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            if self?.locationCompletion != nil {
                print("⚠️ Location request timed out")
                self?.locationCompletion?(nil)
                self?.locationCompletion = nil
            }
        }
    }
    
    func getCurrentLocation() async -> CLLocation? {
        print("🔄 Getting current location asynchronously...")
        
        // 在 App Intent 模式下不启动位置更新
        if shouldSkipLocationOperation(operation: "getCurrentLocation") {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            // 使用标志位防止多次恢复continuation
            var hasResumed = false
            
            // 设置超时，防止continuation泄漏
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 20_000_000_000) // 20秒超时
                if !hasResumed {
                    hasResumed = true
                    print("⚠️ Location request timed out after 20 seconds")
                    continuation.resume(returning: nil)
                }
            }
            
            // 首先尝试使用 requestLocation
            requestLocation { location in
                timeoutTask.cancel() // 取消超时任务
                if !hasResumed {
                    hasResumed = true
                    if let location = location {
                        print("✅ Location obtained successfully: \(location.coordinate)")
                    } else {
                        print("❌ Location request failed")
                    }
                    continuation.resume(returning: location)
                }
            }
        }
    }
    
    // 添加真机位置获取支持，使用持续更新
    func startLocationUpdates() {
        print("🔄 Starting location updates...")
        
        // 在 App Intent 模式下不启动位置更新
        if shouldSkipLocationOperation(operation: "startLocationUpdates") {
            return
        }
        
        // 检查位置服务状态
        guard locationServicesEnabled else {
            print("❌ Cannot start location updates: Location services disabled")
            return
        }
        
        // 检查权限状态
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("❌ Cannot start location updates: Location authorization not granted")
            return
        }
        
        // 更新位置精度设置
        updateLocationAccuracy()
        
        // 开始位置更新
        locationManager.startUpdatingLocation()
        isLocationUpdateActive = true
        
        print("✅ Location updates started successfully")
    }
    
    func stopLocationUpdates() {
        print("🛑 Stopping location updates...")
        isLocationUpdateActive = false
        locationManager.stopUpdatingLocation()
        print("✅ Location updates stopped")
    }
    
    // 检查位置服务状态
    var isLocationServiceActive: Bool {
        return locationManager.location != nil && isLocationUpdateActive
    }
    
    // 添加模拟器位置支持
    func getSimulatorLocation() -> CLLocation? {
        #if targetEnvironment(simulator)
        // 在模拟器中返回一个默认位置（北京天安门）
        let defaultCoordinate = CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
        let defaultLocation = CLLocation(coordinate: defaultCoordinate, altitude: 44.0, horizontalAccuracy: 5.0, verticalAccuracy: 5.0, timestamp: Date())
        print("📍 Using simulator default location: \(defaultCoordinate)")
        return defaultLocation
        #else
        return nil
        #endif
    }
    
    // 获取位置（优先真实位置，模拟器环境使用默认位置）
    func getLocationWithFallback() async -> CLLocation? {
        print("🔄 Attempting to get location with fallback...")
        
        // 在 App Intent 模式下跳过位置获取
        if shouldSkipLocationOperation(operation: "getLocationWithFallback") {
            return nil
        }
        
        // 检查位置服务状态
        guard locationServicesEnabled else {
            print("❌ Location services are disabled")
            return nil
        }
        
        // 检查权限状态
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("❌ Location authorization not granted")
            return nil
        }
        
        // 首先尝试获取真实位置
        if let realLocation = await getCurrentLocation() {
            print("✅ Real location obtained: \(realLocation.coordinate)")
            return realLocation
        }
        
        print("⚠️ Real location failed, trying simulator fallback...")
        
        // 如果真实位置获取失败，在模拟器中使用默认位置
        if let simulatorLocation = getSimulatorLocation() {
            print("📍 Using simulator fallback location")
            return simulatorLocation
        }
        
        print("❌ All location methods failed")
        return nil
    }
    
    // 获取宏观地点信息
    func getDetailedLocationInfo(for location: CLLocation) async -> DetailedLocationInfo {
        print("🔄 Getting detailed location info...")
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                print("⚠️ No placemarks found")
                return DetailedLocationInfo()
            }
            
            print("✅ Detailed location info obtained")
            return DetailedLocationInfo(
                street: placemark.thoroughfare,
                city: placemark.locality,
                state: placemark.administrativeArea,
                country: placemark.country,
                postalCode: placemark.postalCode,
                administrativeArea: placemark.administrativeArea,
                subLocality: placemark.subLocality
            )
        } catch {
            print("❌ Geocoding failed with error: \(error)")
            return DetailedLocationInfo()
        }
    }
    
    // 获取当前位置的完整信息（包括坐标和宏观地点信息）
    func getCurrentLocationWithDetails() async -> (location: CLLocation?, details: DetailedLocationInfo) {
        print("🔄 Getting current location with details...")
        
        // 在 App Intent 模式下不启动位置更新
        if shouldSkipLocationOperation(operation: "getCurrentLocationWithDetails") {
            return (nil, DetailedLocationInfo())
        }
        
        // 检查位置服务状态
        guard locationServicesEnabled else {
            print("❌ Location services are disabled")
            return (nil, DetailedLocationInfo())
        }
        
        // 检查权限状态
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("❌ Location authorization not granted: \(authorizationStatus.rawValue)")
            return (nil, DetailedLocationInfo())
        }
        
        // 使用回退机制获取位置
        guard let location = await getLocationWithFallback() else {
            print("❌ Failed to get location with fallback")
            return (nil, DetailedLocationInfo())
        }
        
        print("✅ Location obtained: \(location.coordinate)")
        let details = await getDetailedLocationInfo(for: location)
        return (location, details)
    }
    
    // 强制刷新位置
    func forceLocationRefresh() async -> CLLocation? {
        print("🔄 Force refreshing location...")
        
        // 在 App Intent 模式下跳过位置刷新
        if shouldSkipLocationOperation(operation: "forceLocationRefresh") {
            return nil
        }
        
        // 停止当前更新
        stopLocationUpdates()
        
        // 等待一小段时间
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        
        // 重新开始更新
        startLocationUpdates()
        
        // 等待位置更新
        return await getCurrentLocation()
    }
    
    // MARK: - App Intent Mode Control
    
    func setAppIntentMode(_ enabled: Bool) {
        isAppIntentMode = enabled
        if enabled {
            print("📱 App Intent mode enabled: Location services will not auto-start")
            // 如果位置更新正在运行，停止它们
            if isLocationUpdateActive {
                stopLocationUpdates()
            }
        } else {
            print("📱 App Intent mode disabled: Location services can auto-start")
        }
    }
    
    /// 检查当前是否为 App Intent 模式
    var isAppIntentMode: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "isAppIntentMode")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isAppIntentMode")
        }
    }
    
    /// 在 App Intent 模式下跳过位置操作的辅助方法
    private func shouldSkipLocationOperation(operation: String) -> Bool {
        if isAppIntentMode {
            print("📱 App Intent mode: Skipping location operation: \(operation)")
            return true
        }
        return false
    }
    
    // MARK: - Location Permission Management
    
    // MARK: - Public Methods
    
    /// Manually request location permission - useful for user-initiated permission requests
    func manuallyRequestLocationPermission() {
        print("🔧 Manual location permission request initiated")
        
        // Check current status first
        let currentStatus = locationManager.authorizationStatus
        print("Current authorization status: \(currentStatus.rawValue)")
        
        switch currentStatus {
        case .notDetermined:
            print("Requesting when in use authorization...")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("❌ Location permission denied or restricted")
            // Provide user guidance
            locationError = "Location access denied. Please enable in Settings → CardPilot → Location"
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location permission already granted")
            startLocationUpdates()
        @unknown default:
            print("Unknown authorization status: \(currentStatus)")
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    /// Check if location permission is available and provide user guidance
    func checkLocationPermissionStatus() -> (isAvailable: Bool, userMessage: String?) {
        let currentStatus = locationManager.authorizationStatus
        
        switch currentStatus {
        case .notDetermined:
            return (false, "Location permission not determined. Please grant permission when prompted.")
        case .denied:
            return (false, "Location access denied. Go to Settings → CardPilot → Location → While Using App")
        case .restricted:
            return (false, "Location access restricted by parental controls or device policy.")
        case .authorizedWhenInUse, .authorizedAlways:
            return (true, nil)
        @unknown default:
            return (false, "Unknown location permission status.")
        }
    }
}

// 宏观地点信息数据结构
struct DetailedLocationInfo {
    let street: String?
    let city: String?
    let state: String?
    let country: String?
    let postalCode: String?
    let administrativeArea: String?
    let subLocality: String?
    
    init(street: String? = nil, 
         city: String? = nil, 
         state: String? = nil, 
         country: String? = nil, 
         postalCode: String? = nil, 
         administrativeArea: String? = nil, 
         subLocality: String? = nil) {
        self.street = street
        self.city = city
        self.state = state
        self.country = country
        self.postalCode = postalCode
        self.administrativeArea = administrativeArea
        self.subLocality = subLocality
    }
    
    // 检查是否有任何地点信息
    var hasLocationInfo: Bool {
        return street != nil || city != nil || state != nil || country != nil || 
               postalCode != nil || administrativeArea != nil || subLocality != nil
    }
    
    // 获取格式化的地点字符串
    var formattedString: String {
        var parts: [String] = []
        
        if let street = street, !street.isEmpty {
            parts.append(street)
        }
        if let city = city, !city.isEmpty {
            parts.append(city)
        }
        if let state = state, !state.isEmpty {
            parts.append(state)
        }
        if let country = country, !country.isEmpty {
            parts.append(country)
        }
        
        return parts.isEmpty ? "Unknown location" : parts.joined(separator: ", ")
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        print("📍 Location updated: \(location.coordinate), accuracy: \(location.horizontalAccuracy)m")
        
        // 检查位置精度
        if location.horizontalAccuracy <= 100 {
            print("✅ Location accuracy is good: \(location.horizontalAccuracy)m")
        } else {
            print("⚠️ Location accuracy is poor: \(location.horizontalAccuracy)m")
        }
        
        self.location = location
        
        // 如果有等待的completion，立即返回
        if let completion = locationCompletion {
            print("✅ Returning location to completion handler")
            completion(location)
            locationCompletion = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager failed with error: \(error.localizedDescription)")
        
        // 添加调试信息
        print("🔍 Debug: Current App Intent mode: \(isAppIntentMode)")
        print("🔍 Debug: Location services enabled: \(locationServicesEnabled)")
        print("🔍 Debug: Authorization status: \(authorizationStatus.rawValue)")
        print("🔍 Debug: Is location update active: \(isLocationUpdateActive)")
        
        // 处理特定错误类型
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("❌ Location access denied by user")
                print("🔍 Debug: This error occurs when user denies location permission")
            case .locationUnknown:
                print("⚠️ Location temporarily unavailable")
            case .network:
                print("⚠️ Network error occurred")
            case .headingFailure:
                print("⚠️ Heading failure")
            case .rangingUnavailable:
                print("⚠️ Ranging unavailable")
            case .rangingFailure:
                print("⚠️ Ranging failure")
            default:
                print("⚠️ Other location error: \(clError.code.rawValue)")
            }
        }
        
        // 通知completion handler
        locationCompletion?(nil)
        locationCompletion = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let oldStatus = authorizationStatus
        authorizationStatus = manager.authorizationStatus
        
        print("🔄 Location authorization changed from \(oldStatus.rawValue) to \(authorizationStatus.rawValue)")
        
        // 重新检查位置服务状态
        checkLocationServicesStatus()
        
        // 在 App Intent 模式下跳过自动位置更新
        if isAppIntentMode {
            print("📱 App Intent mode: Skipping automatic location updates after authorization change")
            return
        }
        
        // 根据权限状态调整位置更新
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location permission granted, starting updates")
            startLocationUpdates()
        case .denied, .restricted:
            print("❌ Location permission denied, stopping updates")
            stopLocationUpdates()
        case .notDetermined:
            print("⏳ Location permission not determined")
        @unknown default:
            print("❓ Unknown authorization status")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // 兼容iOS 14之前的版本
        locationManagerDidChangeAuthorization(manager)
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("📍 Started monitoring region: \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("❌ Region monitoring failed: \(error.localizedDescription)")
    }
}

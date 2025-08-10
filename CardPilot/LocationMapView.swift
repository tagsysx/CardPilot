//
//  LocationMapView.swift
//  CardPilot
//
//  Created by Lei Yang on 12/19/2024.
//

import SwiftUI
import MapKit

struct LocationMapView: View {
    let sessions: [NFCSessionData]
    @State private var region: MKCoordinateRegion
    @State private var mapType: MKMapType = .standard
    
    init(sessions: [NFCSessionData]) {
        self.sessions = sessions
        
        // 初始化地图区域
        let coordinates: [CLLocationCoordinate2D] = sessions.compactMap { session in
            guard let lat = session.latitude, let lon = session.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        
        if !coordinates.isEmpty {
            let latitudes = coordinates.map { $0.latitude }
            let longitudes = coordinates.map { $0.longitude }
            
            let minLat = latitudes.min() ?? 0.0
            let maxLat = latitudes.max() ?? 0.0
            let minLon = longitudes.min() ?? 0.0
            let maxLon = longitudes.max() ?? 0.0
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2.0,
                longitude: (minLon + maxLon) / 2.0
            )
            
            let latDelta = max(abs(maxLat - minLat) * 1.2, 0.01)
            let lonDelta = max(abs(maxLon - minLon) * 1.2, 0.01)
            
            self._region = State(initialValue: MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            ))
        } else {
            // 默认位置（如果没有GPS数据）
            self._region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map")
                    .foregroundColor(.blue)
                Text("Location on Map")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // 地图类型选择器
                Menu {
                    Button("Standard") { mapType = .standard }
                    Button("Satellite") { mapType = .satellite }
                    Button("Hybrid") { mapType = .hybrid }
                } label: {
                    Image(systemName: "map.fill")
                        .foregroundColor(.blue)
                }
            }
            
            let coordinates: [CLLocationCoordinate2D] = sessions.compactMap { session in
                guard let lat = session.latitude, let lon = session.longitude else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            
            if !coordinates.isEmpty {
                Map(coordinateRegion: $region, annotationItems: coordinates.enumerated().map { index, coordinate in
                    LocationAnnotation(id: index, coordinate: coordinate)
                }) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                            
                            // 显示会话索引
                            Text("\(annotation.id + 1)")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                .mapStyle(mapType == .standard ? .standard : mapType == .satellite ? .hybrid : .hybrid)
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // 坐标信息
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Locations: \(coordinates.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Map shows all NFC session locations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 在Apple Maps中打开第一个位置
                    if let firstCoordinate = coordinates.first {
                        Button(action: { openInAppleMaps(coordinate: firstCoordinate) }) {
                            Label("Open in Maps", systemImage: "map")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("Location not available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("This NFC session doesn't have GPS coordinates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // 在Apple Maps中打开位置
    private func openInAppleMaps(coordinate: CLLocationCoordinate2D) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = "NFC Location"
        mapItem.openInMaps(launchOptions: nil)
    }
}

// 地图标注数据模型
struct LocationAnnotation: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    // 创建示例数据用于预览
    let sampleSessions = [
        NFCSessionData(
            timestamp: Date(),
            latitude: 37.7749,
            longitude: -122.4194,
            locationTag: "Office"
        ),
        NFCSessionData(
            timestamp: Date(),
            latitude: 37.7849,
            longitude: -122.4094,
            locationTag: "Home"
        )
    ]
    
    return LocationMapView(sessions: sampleSessions)
        .padding()
}

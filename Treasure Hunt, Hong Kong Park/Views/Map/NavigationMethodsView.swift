//
//  NavigationMethodsView.swift
//  Treasure Hunt, Hong Kong Park
//
//  导航方式选择视图 - 显示建筑信息和交通方式选择
//

import SwiftUI
import MapKit
import CoreLocation

struct NavigationMethodsView: View {
    let building: Treasure
    let userLocation: CLLocation?
    let distance: CLLocationDistance?
    
    var body: some View {
        VStack(spacing: 0) {
            // 建筑信息卡片
            VStack(alignment: .leading, spacing: 4) {
                Text(building.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack {
                    Text(building.district)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(building.districtColor.opacity(0.2))
                        .foregroundColor(building.districtColor)
                        .cornerRadius(3)
                    
                    if let distance = distance {
                        Text("\(Int(distance.rounded())) m")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(6, corners: [.topLeft, .topRight])
            
            // 交通方式按钮
            VStack(spacing: 6) {
                Text("Choose Transportation")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 6) {
                    // 驾车
                    NavigationMethodButton(
                        icon: "car.fill",
                        title: "Drive",
                        color: appGreen
                    ) {
                        openAppleMaps(transportType: .automobile)
                    }
                    
                    // 步行
                    NavigationMethodButton(
                        icon: "figure.walk",
                        title: "Walk",
                        color: appGreen
                    ) {
                        openAppleMaps(transportType: .walking)
                    }
                    
                    // 公共交通
                    NavigationMethodButton(
                        icon: "tram.fill",
                        title: "Transit",
                        color: appGreen
                    ) {
                        openAppleMaps(transportType: .transit)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
    }
    
    // 打开Apple Maps导航
    private func openAppleMaps(transportType: MKDirectionsTransportType) {
        guard let userLocation = userLocation else {
            print("⚠️ User location not available")
            return
        }
        
        let sourcePlacemark = MKPlacemark(coordinate: userLocation.coordinate)
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        sourceItem.name = "Your Location"
        
        let destinationPlacemark = MKPlacemark(coordinate: building.coordinate)
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        destinationItem.name = building.name
        
        let launchOptions: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: transportType.appleMapsDirectionMode,
            MKLaunchOptionsShowsTrafficKey: true
        ]
        
        MKMapItem.openMaps(
            with: [sourceItem, destinationItem],
            launchOptions: launchOptions
        )
        
        print("🗺️ Opening Apple Maps - \(transportType.description) to \(building.name)")
    }
}

// 交通方式按钮
struct NavigationMethodButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(4)
        }
    }
}

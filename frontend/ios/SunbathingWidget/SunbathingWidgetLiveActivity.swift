//
//  SunbathingWidgetLiveActivity.swift
//  SunbathingWidget
//
//  Created by Veli Bilir on 24.07.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

// This structure MUST be exactly named LiveActivitiesAppAttributes for the live_activities plugin
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState
    public struct ContentState: Codable, Hashable { }
    var id = UUID()
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String {
        return "\(id)_\(key)"
    }
}

let sharedDefault = UserDefaults(suiteName: "group.com.velibilir.yolkut")!

@available(iOSApplicationExtension 16.1, *)
struct YolKutTaskLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            let title = sharedDefault.string(forKey: context.attributes.prefixedKey("title")) ?? ""
            let subtitle = sharedDefault.string(forKey: context.attributes.prefixedKey("subtitle")) ?? ""
            let timeValue = sharedDefault.string(forKey: context.attributes.prefixedKey("timeValue")) ?? ""
            let iconName = sharedDefault.string(forKey: context.attributes.prefixedKey("iconName")) ?? "sun.max.fill"
            let taskType = sharedDefault.string(forKey: context.attributes.prefixedKey("taskType")) ?? "sunbathing"
            
            // Lock screen/banner UI
            VStack(alignment: .center) {
                HStack {
                    Image(systemName: iconName)
                        .foregroundColor(getColor(for: taskType))
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.top, 12)
                
                Text(timeValue)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(getColor(for: taskType))
                    .padding(.bottom, 12)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 8)
            }
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)
            
        } dynamicIsland: { context in
            let title = sharedDefault.string(forKey: context.attributes.prefixedKey("title")) ?? ""
            let subtitle = sharedDefault.string(forKey: context.attributes.prefixedKey("subtitle")) ?? ""
            let timeValue = sharedDefault.string(forKey: context.attributes.prefixedKey("timeValue")) ?? ""
            let iconName = sharedDefault.string(forKey: context.attributes.prefixedKey("iconName")) ?? "sun.max.fill"
            let taskType = sharedDefault.string(forKey: context.attributes.prefixedKey("taskType")) ?? "sunbathing"
            
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: iconName)
                        .foregroundColor(getColor(for: taskType))
                        .font(.title2)
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timeValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(getColor(for: taskType))
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } compactLeading: {
                Image(systemName: iconName)
                    .foregroundColor(getColor(for: taskType))
            } compactTrailing: {
                Text(timeValue)
                    .foregroundColor(getColor(for: taskType))
            } minimal: {
                Image(systemName: iconName)
                    .foregroundColor(getColor(for: taskType))
            }
            .keylineTint(getColor(for: taskType))
        }
    }
    
    func getColor(for taskType: String) -> Color {
        switch taskType {
        case "study": return Color.blue
        case "sunbathing": return Color.orange
        case "workout": return Color.green
        case "pacer": return Color.purple
        default: return Color.orange
        }
    }
}

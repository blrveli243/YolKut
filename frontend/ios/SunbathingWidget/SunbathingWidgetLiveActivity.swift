//
//  SunbathingWidgetLiveActivity.swift
//  SunbathingWidget
//
//  Created by Veli Bilir on 24.07.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SunbathingWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
    }
    var totalDurationSeconds: Int
    var isFrontSide: Bool
}

struct SunbathingWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SunbathingWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack(alignment: .center) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                    Text(context.attributes.isFrontSide ? "Ön Yüz (Göğüs/Karın)" : "Arka Yüz (Sırt/Bacak)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.top, 12)
                
                Text(timeString(from: context.state.remainingSeconds))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                    .padding(.bottom, 12)
            }
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timeString(from: context.state.remainingSeconds))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.isFrontSide ? "Güneşlenme: Ön Yüz" : "Güneşlenme: Arka Yüz")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } compactLeading: {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.orange)
            } compactTrailing: {
                Text(timeString(from: context.state.remainingSeconds))
                    .foregroundColor(.orange)
            } minimal: {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.orange)
            }
            .keylineTint(Color.orange)
        }
    }
    
    func timeString(from totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}


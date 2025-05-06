//
//  TriWalkWidget.swift
//  TriWalkWidget
//
//  Created by Sebin Kwon on 4/22/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WalkTodaySummaryEntry {
        WalkTodaySummaryEntry(
            date: Date(),
            summary: WalkTodaySummary(date: Date(), distance: 0.0, steps: 0, duration: 0, isWalkToday: false)
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WalkTodaySummaryEntry) -> ()) {
        let summary = WidgetDataManager.loadWalkSummary() ??
        WalkTodaySummary(date: Date(), distance: 2.5, steps: 3500, duration: 1800, isWalkToday: true)
        
        let entry = WalkTodaySummaryEntry(date: Date(), summary: summary)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [WalkTodaySummaryEntry] = []
        
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        
        let summary = WidgetDataManager.loadWalkSummary() ??
        WalkTodaySummary(date: currentDate, distance: 0, steps: 0,
                         duration: 0, isWalkToday: false)
        
        let entry = WalkTodaySummaryEntry(date: currentDate, summary: summary)
        entries.append(entry)
        
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        
        let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate))
        completion(timeline)
    }
    
    //    func relevances() async -> WidgetRelevances<Void> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}



struct WalkTodaySummaryEntry: TimelineEntry {
    let date: Date
    let summary: WalkTodaySummary
}


struct TriWalkWidgetEntryView : View {
    var entry: Provider.Entry
    
    var formattedDuration: String {
        let hours = Int(entry.summary.duration) / 3600
        let minutes = Int(entry.summary.duration) % 3600 / 60
        let seconds = Int(entry.summary.duration) % 60
        
        if hours > 0 {
            return String(format: "%d시간 %d분", hours, minutes)
        } else {
            return String(format: "%d분 %d초", minutes, seconds)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "figure.walk")
                        .font(.title2)
                    Text("오늘의 산책")
                        .font(.headline)
                    Spacer()
                }
                .padding(.bottom, 4)
                
                if entry.summary.isWalkToday {
                    HStack {
                        Image(systemName: "ruler")
                            .frame(width: 20)
                        Text(String(format: "%.1f km", entry.summary.distance))
                    }
                    
                    HStack {
                        Image(systemName: "shoe")
                            .frame(width: 20)
                        Text("\(entry.summary.steps) 걸음")
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .frame(width: 20)
                        Text(formattedDuration)
                    }
                    Spacer()
                } else {
                    Text("아직 산책을\n하지 않았어요!")
                        .font(.title3)
                    Spacer()
                }
            }
    }
}

struct TriWalkWidget: Widget {
    let kind: String = "TriWalkWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                TriWalkWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                TriWalkWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("오늘의 산책 여행")
        .description("오늘의 산책 여행 기록을 확인해 보세요.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    TriWalkWidget()
} timeline: {
    WalkTodaySummaryEntry(
        date: Date(),
        summary: WalkTodaySummary(date: Date(), distance: 2.5, steps: 3500, duration: 1800, isWalkToday: false)
    )
    WalkTodaySummaryEntry(
        date: Date(),
        summary: WalkTodaySummary(date: Date(), distance: 2.5, steps: 3500, duration: 1800, isWalkToday: true)
    )
}

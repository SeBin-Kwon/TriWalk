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
        
//        SimpleEntry(date: Date(), emoji: "😀")
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


//struct SimpleEntry: TimelineEntry {
//    let date: Date
//    let emoji: String
//}

struct TriWalkWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text(entry.date, style: .time)
                .bold()
            Text("거리: \(entry.summary.distance)")
            Text("걸음수: \(entry.summary.steps)")
            Text("시간: \(entry.summary.duration)")
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
        summary: WalkTodaySummary(date: Date(), distance: 2.5, steps: 3500, duration: 1800, isWalkToday: true)
    )
//    SimpleEntry(date: .now, emoji: "🤩")
}

import ActivityKit
import SwiftUI
import WidgetKit

@main
struct ReadingDynamicWidgetBundle: WidgetBundle {
  var body: some Widget {
    ReadingDynamicLiveActivity()
  }
}

struct ReadingActivityView: View {
  let context: ActivityViewContext<ReadingActivityAttributes>

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(context.attributes.bookTitle)
        .font(.headline)
        .lineLimit(1)

      Text(context.state.chapter)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(1)

      ProgressView(value: context.state.progress)
        .tint(.mint)

      Text("\(Int(context.state.progress * 100))% read")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(16)
    .activityBackgroundTint(Color.black.opacity(0.86))
    .activitySystemActionForegroundColor(.mint)
  }
}

struct ReadingDynamicLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: ReadingActivityAttributes.self) { context in
      ReadingActivityView(context: context)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text("Read")
            .font(.headline)
            .foregroundStyle(.mint)
        }

        DynamicIslandExpandedRegion(.trailing) {
          Text("\(Int(context.state.progress * 100))%")
            .font(.headline.monospacedDigit())
            .foregroundStyle(.mint)
        }

        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 6) {
            Text(context.state.chapter)
              .font(.caption)
              .lineLimit(1)
            ProgressView(value: context.state.progress)
              .tint(.mint)
          }
        }
      } compactLeading: {
        Image(systemName: "book.fill")
          .foregroundStyle(.mint)
      } compactTrailing: {
        Text("\(Int(context.state.progress * 100))%")
          .font(.caption2.monospacedDigit())
          .foregroundStyle(.mint)
      } minimal: {
        ZStack {
          Circle()
            .stroke(.mint.opacity(0.2), lineWidth: 2)
          Circle()
            .trim(from: 0, to: context.state.progress)
            .stroke(.mint, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .rotationEffect(.degrees(-90))
        }
      }
      .keylineTint(.mint)
    }
  }
}

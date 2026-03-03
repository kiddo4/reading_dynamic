import ActivityKit
import Foundation

@available(iOS 16.2, *)
final class LiveActivityManager {
  static let shared = LiveActivityManager()

  private var currentActivity: Activity<ReadingActivityAttributes>?

  private init() {}

  func areActivitiesEnabled() -> Bool {
    ActivityAuthorizationInfo().areActivitiesEnabled
  }

  func start(bookTitle: String, chapter: String, progress: Double) async -> Bool {
    guard areActivitiesEnabled() else {
      return false
    }

    let attributes = ReadingActivityAttributes(bookTitle: bookTitle)
    let initialState = ReadingActivityAttributes.ContentState(
      progress: normalized(progress),
      chapter: chapter
    )

    do {
      currentActivity = try Activity.request(
        attributes: attributes,
        content: .init(state: initialState, staleDate: nil),
        pushType: nil
      )
      return true
    } catch {
      print("[LiveActivity] Failed to start activity: \(error)")
      return false
    }
  }

  func update(chapter: String, progress: Double) async -> Bool {
    let state = ReadingActivityAttributes.ContentState(
      progress: normalized(progress),
      chapter: chapter
    )

    if let activity = currentActivity {
      await activity.update(.init(state: state, staleDate: nil))
      return true
    }

    if let existing = Activity<ReadingActivityAttributes>.activities.first {
      currentActivity = existing
      await existing.update(.init(state: state, staleDate: nil))
      return true
    }

    return false
  }

  func end() async {
    if let activity = currentActivity {
      await activity.end(nil, dismissalPolicy: .immediate)
      currentActivity = nil
      return
    }

    for activity in Activity<ReadingActivityAttributes>.activities {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
  }

  private func normalized(_ value: Double) -> Double {
    min(max(value, 0), 1)
  }
}

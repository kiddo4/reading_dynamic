import ActivityKit

struct ReadingActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var progress: Double
    var chapter: String
  }

  var bookTitle: String
}

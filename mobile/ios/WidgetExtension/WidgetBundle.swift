import SwiftUI
import WidgetKit

@main
struct GreatMemoriesWidgetBundle: WidgetBundle {
  var body: some Widget {
    GreatMemoriesRandomWidget()
    GreatMemoriesMemoryWidget()
  }
}

import SwiftUI

struct DevInjectionToken {}

@propertyWrapper
struct DevObserveInjection {
    var wrappedValue: DevInjectionToken

    init() {
        self.wrappedValue = DevInjectionToken()
    }
}

extension View {
    @ViewBuilder
    func devEnableInjection() -> some View {
        self
    }
}

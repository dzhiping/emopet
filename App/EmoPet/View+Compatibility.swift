import SwiftUI

extension View {
    /// iOS 17+ 符号弹跳；低版本静默降级
    @ViewBuilder
    func petSymbolBounce<T: Equatable>(trigger: T) -> some View {
        if #available(iOS 17.0, *) {
            symbolEffect(.bounce, value: trigger)
        } else {
            self
        }
    }
}

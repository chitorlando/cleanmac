import CleanMacUI

/// A planned feature shown in the sidebar until it is implemented.
struct UpcomingFeature: Identifiable {
    let title: String
    let symbolName: String

    var id: String { title }
}

extension UpcomingFeature {
    static let roadmap: [UpcomingFeature] = [
        UpcomingFeature(title: "Desinstalador", symbolName: "app.badge.checkmark"),
        UpcomingFeature(title: "Archivos grandes", symbolName: "doc.richtext"),
        UpcomingFeature(title: "Mapa del disco", symbolName: "chart.pie.fill"),
        UpcomingFeature(title: "Duplicados", symbolName: "doc.on.doc.fill"),
        UpcomingFeature(title: "Privacidad", symbolName: "hand.raised.fill"),
        UpcomingFeature(title: "Ítems de inicio", symbolName: "power"),
        UpcomingFeature(title: "Mantenimiento", symbolName: "wrench.and.screwdriver.fill"),
        UpcomingFeature(title: "Monitor", symbolName: "gauge.with.dots.needle.67percent")
    ]
}

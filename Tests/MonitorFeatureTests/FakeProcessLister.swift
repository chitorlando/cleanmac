import MonitorFeature

struct FakeProcessLister: ProcessListing {
    let readings: ReadingQueue<[ProcessSample]>
    func processes() -> [ProcessSample] { readings.next() ?? [] }
}

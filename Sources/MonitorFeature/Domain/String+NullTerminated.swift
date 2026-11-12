extension String {
    /// The UTF-8 text a C function wrote into `buffer`, up to its null terminator.
    init(nullTerminated buffer: [CChar]) {
        let bytes = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        self.init(decoding: bytes, as: UTF8.self)
    }
}

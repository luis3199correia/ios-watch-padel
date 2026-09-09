import Testing
@testable import PadelUI

@Suite("PadelColor hex decoding")
struct PadelColorTests {

    @Test("Decodes each channel independently from a 0xRRGGBB literal")
    func decodesChannels() {
        let c = hexComponents(0x2FE6A8)
        #expect(c.red == Double(0x2F) / 255)
        #expect(c.green == Double(0xE6) / 255)
        #expect(c.blue == Double(0xA8) / 255)
    }

    @Test("Black decodes to all-zero components")
    func black() {
        let c = hexComponents(0x000000)
        #expect(c.red == 0)
        #expect(c.green == 0)
        #expect(c.blue == 0)
    }

    @Test("White decodes to all-one components")
    func white() {
        let c = hexComponents(0xFFFFFF)
        #expect(c.red == 1)
        #expect(c.green == 1)
        #expect(c.blue == 1)
    }
}

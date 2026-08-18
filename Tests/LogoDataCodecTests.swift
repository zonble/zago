import Foundation
import Testing

@testable import LogoEngine

@Suite
struct LogoDataCodecTests {

    @Test func testBase64EncodingAndDecoding() {
        let text1 = "Hello, World!"
        let encoded1 = LogoDataCodec.base64Encode(text1)
        #expect(encoded1 == "SGVsbG8sIFdvcmxkIQ==")
        #expect(LogoDataCodec.base64Decode(encoded1) == text1)

        let textCJK = "你好世界，哈囉 🚀"
        let encodedCJK = LogoDataCodec.base64Encode(textCJK)
        #expect(LogoDataCodec.base64Decode(encodedCJK) == textCJK)

        #expect(LogoDataCodec.isValidBase64(encoded1) == true)
        #expect(LogoDataCodec.isValidBase64(encodedCJK) == true)
        #expect(LogoDataCodec.isValidBase64("not_valid_b64!!!") == false)
        #expect(LogoDataCodec.isValidBase64("") == false)
    }

    @Test func testURLEncodingAndDecoding() {
        let text = "https://example.com/search?q=你好 世界&tag=123"
        let encoded = LogoDataCodec.urlEncode(text)
        #expect(encoded.contains("%E4%BD%A0%E5%A5%BD"))
        #expect(LogoDataCodec.urlDecode(encoded) == text)
    }

    @Test func testHexEncodingAndDecoding() {
        // Integer numbers
        #expect(LogoDataCodec.hexEncode("255") == "0xFF")
        #expect(LogoDataCodec.hexEncode("0") == "0x0")
        #expect(LogoDataCodec.hexEncode("16") == "0x10")
        #expect(LogoDataCodec.hexEncode("-10") == "-0xA")

        // Hex decoding for 0x format
        #expect(LogoDataCodec.hexDecode("0xFF") == "255")
        #expect(LogoDataCodec.hexDecode("0xff") == "255")
        #expect(LogoDataCodec.hexDecode("0x0") == "0")
        #expect(LogoDataCodec.hexDecode("-0xA") == "-10")

        // Strings
        #expect(LogoDataCodec.hexEncode("abc") == "616263")
        #expect(LogoDataCodec.hexDecode("616263") == "abc")
        #expect(LogoDataCodec.hexDecode("invalid_hex_string") == nil)
    }

    @Test func testCryptographicHashes() {
        // SHA-256 standard vectors
        #expect(
            LogoDataCodec.sha256("")
                == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        )
        #expect(
            LogoDataCodec.sha256("zago")
                == "a8c9c415e3c160a7da0b080e3ad97dbde9fb7dc26f961a9ab36b0f35c1b990eb"
        )

        // SHA-1 standard vectors
        #expect(
            LogoDataCodec.sha1("")
                == "da39a3ee5e6b4b0d3255bfef95601890afd80709"
        )
        #expect(
            LogoDataCodec.sha1("zago")
                == "c638cf03c5bc5b232cd77bce0187768802868ac4"
        )

        // MD5 standard vectors
        #expect(
            LogoDataCodec.md5("")
                == "d41d8cd98f00b204e9800998ecf8427e"
        )
        #expect(
            LogoDataCodec.md5("zago")
                == "d8bbeea6bd5b4499ac006dd6bdece342"
        )
    }

    @Test func testLogoEngineDataCodecPrimitives() {
        let engine = LogoEngine()

        engine.execute("MAKE \"b64res BASE64.ENCODE \"Hello")
        #expect(engine.variables["b64res"] == "SGVsbG8=")

        engine.execute("MAKE \"b64dec BASE64.DECODE \"SGVsbG8=")
        #expect(engine.variables["b64dec"] == "Hello")

        engine.execute("MAKE \"b64valid BASE64? \"SGVsbG8=")
        #expect(engine.variables["b64valid"] == "true")

        engine.execute("MAKE \"b64invalid BASE64? \"hello")
        #expect(engine.variables["b64invalid"] == "false")

        engine.execute("MAKE \"urlenc URL.ENCODE \"你好")
        #expect(engine.variables["urlenc"] == "%E4%BD%A0%E5%A5%BD")

        engine.execute("MAKE \"urldec URL.DECODE \"%E4%BD%A0%E5%A5%BD")
        #expect(engine.variables["urldec"] == "你好")

        engine.execute("MAKE \"hexnum HEX.ENCODE 255")
        #expect(engine.variables["hexnum"] == "0xFF")

        engine.execute("MAKE \"hexdecnum HEX.DECODE \"0xFF")
        #expect(engine.variables["hexdecnum"] == "255")

        engine.execute("MAKE \"hexstr HEX.ENCODE \"abc")
        #expect(engine.variables["hexstr"] == "616263")

        engine.execute("MAKE \"hexdecstr HEX.DECODE \"616263")
        #expect(engine.variables["hexdecstr"] == "abc")

        engine.execute("MAKE \"sha256res HASH.SHA256 \"zago")
        #expect(engine.variables["sha256res"] == "a8c9c415e3c160a7da0b080e3ad97dbde9fb7dc26f961a9ab36b0f35c1b990eb")

        engine.execute("MAKE \"sha1res HASH.SHA1 \"zago")
        #expect(engine.variables["sha1res"] == "c638cf03c5bc5b232cd77bce0187768802868ac4")

        engine.execute("MAKE \"md5res HASH.MD5 \"zago")
        #expect(engine.variables["md5res"] == "d8bbeea6bd5b4499ac006dd6bdece342")
    }
}

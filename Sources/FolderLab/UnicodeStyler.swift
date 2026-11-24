import Foundation
import AppKit

// MARK: - Unicode Folder Renamer Engine (v0.4)

public enum UnicodeStyle: String, CaseIterable, Identifiable {
    case boldSans = "Bold Sans"
    case boldSerif = "Bold Serif"
    case italicSans = "Italic Sans"
    case boldItalic = "Bold Italic"
    case script = "Script Calligraphy"
    case monospace = "Typewriter Mono"
    case doubleStruck = "Double-Struck"
    case fraktur = "Gothic Fraktur"
    case circled = "Circled Bubble"
    case darkBubble = "Dark Bubble"
    case squared = "Boxed Square"
    case darkSquare = "Dark Box"
    case smallCaps = "Small Caps"
    case fullwidth = "Vaporwave Wide"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .boldSans: return "bold"
        case .boldSerif: return "character"
        case .italicSans: return "italic"
        case .boldItalic: return "bold.italic"
        case .script: return "pencil.tip"
        case .monospace: return "chevron.left.forwardslash.chevron.right"
        case .doubleStruck: return "character.cursor.ibeam"
        case .fraktur: return "shield.fill"
        case .circled: return "circle"
        case .darkBubble: return "circle.fill"
        case .squared: return "square"
        case .darkSquare: return "square.fill"
        case .smallCaps: return "textformat.size.smaller"
        case .fullwidth: return "arrow.left.and.right"
        }
    }
}

public enum UnicodeStyler {

    // MARK: - Small Caps Table
    private static let smallCapsMap: [Character: Character] = [
        "a": "ᴀ", "b": "ʙ", "c": "ᴄ", "d": "ᴅ", "e": "ᴇ", "f": "ꜰ", "g": "ɢ", "h": "ʜ",
        "i": "ɪ", "j": "ᴊ", "k": "ᴋ", "l": "ʟ", "m": "ᴍ", "n": "ɴ", "o": "ᴏ", "p": "ᴘ",
        "q": "ǫ", "r": "ʀ", "s": "ꜱ", "t": "ᴛ", "u": "ᴜ", "v": "ᴠ", "w": "ᴡ", "x": "x",
        "y": "ʏ", "z": "ᴢ",
        "A": "ᴀ", "B": "ʙ", "C": "ᴄ", "D": "ᴅ", "E": "ᴇ", "F": "ꜰ", "G": "ɢ", "H": "ʜ",
        "I": "ɪ", "J": "ᴊ", "K": "ᴋ", "L": "ʟ", "M": "ᴍ", "N": "ɴ", "O": "ᴏ", "P": "ᴘ",
        "Q": "ǫ", "R": "ʀ", "S": "ꜱ", "T": "ᴛ", "U": "ᴜ", "V": "ᴠ", "W": "ᴡ", "X": "x",
        "Y": "ʏ", "Z": "ᴢ"
    ]

    // MARK: - Double-Struck Unicode Math Exceptions
    private static let doubleStruckCapExceptions: [Character: Character] = [
        "C": "\u{2102}", "H": "\u{210D}", "N": "\u{2115}", "P": "\u{2119}",
        "Q": "\u{211A}", "R": "\u{211D}", "Z": "\u{2124}"
    ]

    // MARK: - Transform Text
    public static func transform(_ text: String, style: UnicodeStyle) -> String {
        guard !text.isEmpty else { return "" }

        switch style {
        case .boldSans:
            return String(text.map { ch in
                guard let s = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else { return ch }
                if s.value >= 0x41 && s.value <= 0x5A { return Character(UnicodeScalar(0x1D5D4 + (s.value - 0x41))!) }
                if s.value >= 0x61 && s.value <= 0x7A { return Character(UnicodeScalar(0x1D5EE + (s.value - 0x61))!) }
                if s.value >= 0x30 && s.value <= 0x39 { return Character(UnicodeScalar(0x1D7EC + (s.value - 0x30))!) }
                return ch
            })

        case .boldSerif:
            return String(text.map { ch in
                guard let s = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else { return ch }
                if s.value >= 0x41 && s.value <= 0x5A { return Character(UnicodeScalar(0x1D400 + (s.value - 0x41))!) }
                if s.value >= 0x61 && s.value <= 0x7A { return Character(UnicodeScalar(0x1D41A + (s.value - 0x61))!) }
                if s.value >= 0x30 && s.value <= 0x39 { return Character(UnicodeScalar(0x1D7CE + (s.value - 0x30))!) }
                return ch
            })

        case .italicSans:
            return String(text.map { ch in
                guard let s = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else { return ch }
                if s.value >= 0x41 && s.value <= 0x5A { return Character(UnicodeScalar(0x1D608 + (s.value - 0x41))!) }
                if s.value >= 0x61 && s.value <= 0x7A { return Character(UnicodeScalar(0x1D622 + (s.value - 0x61))!) }
                return ch
            })

        case .boldItalic:
            return String(text.map { ch in
                guard let s = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else { return ch }
                if s.value >= 0x41 && s.value <= 0x5A { return Character(UnicodeScalar(0x1D63C + (s.value - 0x41))!) }
                if s.value >= 0x61 && s.value <= 0x7A { return Character(UnicodeScalar(0x1D656 + (s.value - 0x61))!) }
                return ch
            })

        case .script:
            return String(text.map { ch in
                guard let s = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else { return ch }
                if s.value >= 0x41 && s.value <= 0x5A { return Character(UnicodeScalar(0x1D4D0 + (s.value - 0x41))!) }
                if s.value >= 0x61 && s.value <= 0x7A { return Character(UnicodeScalar(0x1D4EA + (s.value - 0x61))!) }
                return ch
            })

        case .monospace:
            return String(text.map { ch in
                guard let s = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else { return ch }
                if s.value >= 0x41 && s.value <= 0x5A { return Character(UnicodeScalar(0x1D670 + (s.value - 0x41))!) }
                if s.value >= 0x61 && s.value <= 0x7A { return Character(UnicodeScalar(0x1D68A + (s.value - 0x61))!) }
                if s.value >= 0x30 && s.value <= 0x39 { return Character(UnicodeScalar(0x1D7F6 + (s.value - 0x30))!) }
                return ch
            })

        case .doubleStruck:
            return String(text.map { ch in
                if let special = doubleStruckCapExceptions[ch] { return special }
                guard let s = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else { return ch }
                if s.value >= 0x41 && s.value <= 0x5A { return Character(UnicodeScalar(0x1D538 + (s.value - 0x41))!) }
                if s.value >= 0x61 && s.value <= 0x7A { return Character(UnicodeScalar(0x1D552 + (s.value - 0x61))!) }
                if s.value >= 0x30 && s.value <= 0x39 { return Character(UnicodeScalar(0x1D7D8 + (s.value - 0x30))!) }
                return ch
            })

        case .fraktur:
            return String(text.map { ch in
                guard let s = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else { return ch }
                if s.value >= 0x41 && s.value <= 0x5A { return Character(UnicodeScalar(0x1D56C + (s.value - 0x41))!) }
                if s.value >= 0x61 && s.value <= 0x7A { return Character(UnicodeScalar(0x1D586 + (s.value - 0x61))!) }
                return ch
            })

        case .circled:
            return String(text.map { ch in
                guard let s = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else { return ch }
                if s.value >= 0x41 && s.value <= 0x5A { return Character(UnicodeScalar(0x24B6 + (s.value - 0x41))!) }
                if s.value >= 0x61 && s.value <= 0x7A { return Character(UnicodeScalar(0x24D0 + (s.value - 0x61))!) }
                if s.value == 0x30 { return "⓪" }
                if s.value >= 0x31 && s.value <= 0x39 { return Character(UnicodeScalar(0x2460 + (s.value - 0x31))!) }
                return ch
            })

        case .darkBubble:
            return String(text.map { ch in
                guard let s = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else { return ch }
                if s.value >= 0x41 && s.value <= 0x5A { return Character(UnicodeScalar(0x1F150 + (s.value - 0x41))!) }
                if s.value >= 0x61 && s.value <= 0x7A { return Character(UnicodeScalar(0x1F150 + (s.value - 0x61))!) }
                if s.value >= 0x31 && s.value <= 0x39 { return Character(UnicodeScalar(0x2776 + (s.value - 0x31))!) }
                if s.value == 0x30 { return "⓿" }
                return ch
            })

        case .squared:
            return String(text.map { ch in
                guard let s = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else { return ch }
                if s.value >= 0x41 && s.value <= 0x5A { return Character(UnicodeScalar(0x1F130 + (s.value - 0x41))!) }
                if s.value >= 0x61 && s.value <= 0x7A { return Character(UnicodeScalar(0x1F130 + (s.value - 0x61))!) }
                return ch
            })

        case .darkSquare:
            return String(text.map { ch in
                guard let s = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else { return ch }
                if s.value >= 0x41 && s.value <= 0x5A { return Character(UnicodeScalar(0x1F170 + (s.value - 0x41))!) }
                if s.value >= 0x61 && s.value <= 0x7A { return Character(UnicodeScalar(0x1F170 + (s.value - 0x61))!) }
                return ch
            })

        case .smallCaps:
            return String(text.map { smallCapsMap[$0] ?? $0 })

        case .fullwidth:
            return String(text.map { ch in
                guard let s = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else { return ch }
                if s.value >= 0x21 && s.value <= 0x7E { return Character(UnicodeScalar(0xFF01 + (s.value - 0x21))!) }
                return ch
            })
        }
    }

    public static func sample(for style: UnicodeStyle) -> String {
        transform("Folder", style: style)
    }

    // MARK: - Direct Finder Folder Renamer
    public static func renameFolder(at sourceURL: URL, newName: String) throws -> URL {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw NSError(domain: "FolderLab", code: 1, userInfo: [NSLocalizedDescriptionKey: "Folder name cannot be empty."])
        }

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: sourceURL.path, isDirectory: &isDir), isDir.boolValue else {
            throw NSError(domain: "FolderLab", code: 2, userInfo: [NSLocalizedDescriptionKey: "Selected item is not a valid directory."])
        }

        let parentDir = sourceURL.deletingLastPathComponent()
        let destURL = parentDir.appendingPathComponent(trimmedName, isDirectory: true)

        if destURL.path == sourceURL.path {
            return sourceURL
        }

        if FileManager.default.fileExists(atPath: destURL.path) {
            throw NSError(domain: "FolderLab", code: 3, userInfo: [NSLocalizedDescriptionKey: "A folder named '\(trimmedName)' already exists in this location."])
        }

        try FileManager.default.moveItem(at: sourceURL, to: destURL)
        return destURL
    }
}

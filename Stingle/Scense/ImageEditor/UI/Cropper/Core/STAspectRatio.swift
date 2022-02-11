//
//  STAspectRatio.swift
//  ImageEditor
//
//  Created by Shahen Antonyan on 01/12/22.
//

import Foundation

enum STAspectRatio {
    case original
    case freeForm
    case square
    case ratio(width: Int, height: Int)

    var rotated: STAspectRatio {
        switch self {
        case let .ratio(width, height):
            return .ratio(width: height, height: width)
        default:
            return self
        }
    }

    var description: String {
        switch self {
        case .original:
            return "editor_original".localized.uppercased()
        case .freeForm:
            return "editor_freeform".localized.uppercased()
        case .square:
            return "editor_square".localized.uppercased()
        case let .ratio(width, height):
            return "\(width):\(height)"
        }
    }
}

// MARK: Codable

extension STAspectRatio: Codable {
    enum CodingKeys: String, CodingKey {
        case description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let desc = try container.decodeIfPresent(String.self, forKey: .description) else {
            self = .freeForm
            return
        }
        switch desc {
        case "editor_original".localized.uppercased():
            self = .original
        case "editor_freeform".localized.uppercased():
            self = .freeForm
        case "editor_square".localized.uppercased():
            self = .square
        default:
            let numberStrings = desc.split(separator: ":")
            if numberStrings.count == 2,
                let width = Int(numberStrings[0]),
                let height = Int(numberStrings[1]) {
                self = .ratio(width: width, height: height)
            } else {
                self = .freeForm
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(description, forKey: .description)
    }
}

extension STAspectRatio: Equatable {
    static func == (lhs: STAspectRatio, rhs: STAspectRatio) -> Bool {
        switch (lhs, rhs) {
        case (let .ratio(lhsWidth, lhsHeight), let .ratio(rhsWidth, rhsHeight)):
            return lhsWidth == rhsWidth && lhsHeight == rhsHeight
        case (.original, .original),
             (.freeForm, .freeForm),
             (.square, .square):
            return true
        default:
            return false
        }
    }
}

//
//  SwiftType.swift
//  swift-type-analyzer
//
//  Created by Noah Peeters on 28.11.20.
//

import Foundation

public struct SwiftType: CustomStringConvertible, Hashable, Codable {
    public let fullyQuallifiedName: [String]
    public let kind: Kind

    public enum Kind: String, Hashable, Codable {
        case `struct`
        case `enum`
        case `class`
        case `protocol`
        case `function`
        case `typealias`
        case genericTypeParam
    }

    public init(fullyQuallifiedName: [String], kind: Kind) {
        self.fullyQuallifiedName = fullyQuallifiedName
        self.kind = kind
    }

    public var description: String {
        "\(name) (\(kind))"
    }

    public var name: String {
        fullyQuallifiedName.joined(separator: ".")
    }
}

extension SwiftType {
    var module: String {
        fullyQuallifiedName.count > 1 ? fullyQuallifiedName[0] : ""
    }

    var typeNameWithputModule: String {
        fullyQuallifiedName.count > 1 ? String(fullyQuallifiedName.dropFirst().joined(separator: ".")) : name
    }
}

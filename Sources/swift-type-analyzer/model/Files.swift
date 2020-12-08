//
//  Files.swift
//  
//
//  Created by Noah Peeters on 26.11.20.
//

import Foundation

typealias Files = [[String: File]]

public protocol WithSubstructures {
    var substructures: [Structure]? { get }
}

public struct File: Decodable, WithSubstructures {
    enum CodingKeys: String, CodingKey {
        case substructures = "key.substructure"
    }
    
    public var substructures: [Structure]?
}

public struct Structure: Decodable, WithSubstructures {
    enum CodingKeys: String, CodingKey {
        case substructures = "key.substructure"
        case kind = "key.kind"
        case typeId = "key.typeusr"
    }
    
    public enum Kind: String, Decodable {
        case primitive
        case buildIn
        case `struct` = "source.lang.swift.decl.struct"
        case `protocol` = "source.lang.swift.decl.protocol"
        case `class` = "source.lang.swift.decl.class"
        case genericTypeParam = "source.lang.swift.decl.generic_type_param"
        case `typealias` = "source.lang.swift.decl.typealias"
        case `enum` = "source.lang.swift.decl.enum"
        
        case staticVariable = "source.lang.swift.decl.var.static"
        case instanceVariable = "source.lang.swift.decl.var.instance"
        case globalVariable = "source.lang.swift.decl.var.global"
        case localVariable = "source.lang.swift.decl.var.local"
        
        case enumElement = "source.lang.swift.decl.enumelement"
        case enumCase = "source.lang.swift.decl.enumcase"
        
        case instanceFunction = "source.lang.swift.decl.function.method.instance"
        case staticFunction = "source.lang.swift.decl.function.method.static"
        case classFunction = "source.lang.swift.decl.function.method.class"
        case `subscript` = "source.lang.swift.decl.function.subscript"
        
        case marker = "source.lang.swift.syntaxtype.comment.mark"
        case `extension` = "source.lang.swift.decl.extension"

        case `associatedtype` = "source.lang.swift.decl.associatedtype"
        
        public enum KindType {
            case typeDefinition
            case typeUsage
            case other
        }
        
        var isTypeDefinition: KindType {
            switch self {
            case .marker, .extension, .enumCase, .associatedtype:
                return .other
            case .primitive, .buildIn, .struct, .protocol, .class, .genericTypeParam, .typealias, .enum:
                return .typeDefinition
            case .staticVariable, .instanceVariable, .globalVariable, .localVariable, .enumElement, .instanceFunction, .staticFunction, .subscript, .classFunction:
                return .typeUsage
            }
        }
    }
    
    public struct TypeID: Decodable {
        let rawString: String
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            rawString = try container.decode(String.self)
        }
    }
    
    public var substructures: [Structure]?
    public var kind: Kind
    public var typeId: TypeID?
}

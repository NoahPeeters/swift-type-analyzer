//
//  StructureAnalyzer.swift
//  swift-type-analyzer
//
//  Created by Noah Peeters on 28.11.20.
//

import Foundation
import CwlDemangle

class StructureAnalyzer {
    static let jsonDecoder = JSONDecoder()

    func traverseStructures(structures: [Structure], callback: (Structure) -> Void) {
        for structure in structures {
            callback(structure)
            if let subStructures = structure.substructures {
                traverseStructures(structures: subStructures, callback: callback)
            }
        }
    }

    func analyzeDocumentation(docURL: URL) throws -> [SwiftType: Int] {
        let docData = try Data(contentsOf: docURL)

        let files = try Self.jsonDecoder.decode(Files.self, from: docData).flatMap { $0.values }



        var usage: [SwiftType: Int] = [:]

        traverseStructures(structures: files.flatMap { $0.substructures ?? [] }) { structure in
            guard let typeId = structure.typeId, structure.kind.isTypeDefinition == .typeUsage else {
                return
            }

            do {
                let symbol: SwiftSymbol = try parseMangledSwiftSymbol(typeId.rawString)

                let swiftTypes = symbol.extractSwiftTypes()
                for type in swiftTypes {
                    usage[type, default: 0] += 1
                }
            } catch {}
        }

        return usage
    }
}

extension SwiftSymbol {
    func extractSwiftTypes() -> [SwiftType] {
        switch kind {
        case .identifier, .dependentGenericParamCount, .tupleElementName:
            return []
        case .emptyList, .firstElementMarker, .throwsAnnotation, .variadicMarker, .errorType:
            assert(children.count == 0)
            return []
        case .type, .typeMangling, .argumentTuple, .returnType, .inOut, .metatype, .dynamicSelf, .existentialMetatype:
            assert(children.count == 1)
            return children[0].extractSwiftTypes()
        case .typeList, .global, .tuple, .dependentGenericType, .dependentGenericSignature, .dependentMemberType, .dependentAssociatedTypeRef, .dependentGenericLayoutRequirement, .tupleElement, .protocolList, .protocolListWithAnyObject, .protocolListWithClass:
            return children.flatMap { $0.extractSwiftTypes() }
        case .dependentGenericParamType:
            guard let name = contents.name else {
                fatalError("Generic Type name missing")
            }
            return [SwiftType(fullyQuallifiedName: [name], kind: .genericTypeParam)]
        case .structure:
            return [SwiftType(fullyQuallifiedName: extractRecursiveName(), kind: .struct)]
        case .class:
            return [SwiftType(fullyQuallifiedName: extractRecursiveName(), kind: .class)]
        case .enum:
            return [SwiftType(fullyQuallifiedName: extractRecursiveName(), kind: .enum)]
        case .protocol:
            return [SwiftType(fullyQuallifiedName: extractRecursiveName(), kind: .protocol)]
        case .typeAlias:
            return [SwiftType(fullyQuallifiedName: extractRecursiveName(), kind: .typealias)]
        case .functionType, .noEscapeFunctionType, .autoClosureType, .escapingAutoClosureType, .cFunctionPointer:
            return [SwiftType(fullyQuallifiedName: ["<FUNCTION>"], kind: .function)] +
                children.flatMap { $0.extractSwiftTypes() }
        case .boundGenericEnum, .boundGenericClass, .boundGenericStructure, .boundGenericTypeAlias, .dependentGenericConformanceRequirement, .dependentGenericSameTypeRequirement:
            assert(children.count == 2)
            return children[0].extractSwiftTypes() + children[1].extractSwiftTypes()
        default:
            fatalError("Unimplemented kind \(kind)")
        }
    }

    private func extractRecursiveName() -> [String] {
        return recursivFlatMap(input: self, valueKeyPath: \.contents.name, recursiveKeyPath: \.children).compactMap { $0 }
    }


    private func recursivFlatMap<Input, Output>(input: Input, valueKeyPath: KeyPath<Input, Output>, recursiveKeyPath: KeyPath<Input, [Input]>) -> [Output] {
        [input[keyPath: valueKeyPath]] + input[keyPath: recursiveKeyPath].flatMap {
            recursivFlatMap(input: $0, valueKeyPath: valueKeyPath, recursiveKeyPath: recursiveKeyPath)
        }
    }
}

extension SwiftSymbol.Contents {
    var name: String? {
        switch self {
        case let .name(name):
            return name
        case let .index(index):
            return "\(index)"
        default:
            return nil
        }
    }
}

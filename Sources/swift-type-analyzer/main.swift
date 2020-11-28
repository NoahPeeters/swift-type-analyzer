import Foundation
import CwlDemangle

//let docURL = URL(fileURLWithPath: "/Users/noahpeeters/Developer/swift-type-analyzer/test/doc.json")
let docURL = URL(fileURLWithPath: "/Users/noahpeeters/Developer/doc.json")

let docData = try Data(contentsOf: docURL)

let jsonDecoder = JSONDecoder()
let files = try jsonDecoder.decode(Files.self, from: docData).flatMap { $0.values }

func traverseStructures(structures: [Structure], callback: (Structure) -> Void) {
    for structure in structures {
        callback(structure)
        if let subStructures = structure.substructures {
            traverseStructures(structures: subStructures, callback: callback)
        }
    }
}


struct SwiftType: CustomStringConvertible, Hashable, Codable {
    let fullyQuallifiedName: [String]
    let kind: Kind
    
    enum Kind: String, Hashable, Codable {
        case `struct`
        case `enum`
        case `class`
        case `protocol`
        case `function`
        case `typealias`
        case genericTypeParam
    }

    init(fullyQuallifiedName: [String], kind: Kind) {
        self.fullyQuallifiedName = fullyQuallifiedName
        self.kind = kind
    }

    var description: String {
        "\(name) (\(kind))"
    }

    var name: String {
        fullyQuallifiedName.joined(separator: ".")
    }
}

var usage: [SwiftType: Int] = [:]

traverseStructures(structures: files.flatMap { $0.substructures ?? [] }) { structure in
    guard let typeId = structure.typeId else {
        return
    }

    do {
        
        if structure.kind.isTypeDefinition == .typeUsage {
            let symbol: SwiftSymbol = try parseMangledSwiftSymbol(typeId.rawString)
            
            let swiftTypes = symbol.extractSwiftTypes()
            for type in swiftTypes {
                usage[type, default: 0] += 1
            }
            
        }
    } catch {}
}

usage
    .sorted(by: { $0.key.name < $1.key.name }  )
    .forEach { (t, count) in
        print("\(t) \(count)")
    }


extension SwiftSymbol {
    func extractSwiftTypes() -> [SwiftType] {
        switch kind {
        case .identifier, .dependentGenericParamCount:
            return []
        case .emptyList, .firstElementMarker:
            assert(children.count == 0)
            return []
        case .type, .typeMangling, .argumentTuple, .returnType, .tupleElement, .protocolList, .inOut, .metatype:
            assert(children.count == 1)
            return children[0].extractSwiftTypes()
        case .typeList, .global, .tuple, .dependentGenericType, .dependentGenericSignature:
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
        case .functionType, .noEscapeFunctionType:
            return [SwiftType(fullyQuallifiedName: ["<FUNCTION>"], kind: .function)] +
                children.flatMap { $0.extractSwiftTypes() }
        case .boundGenericEnum, .boundGenericClass, .boundGenericStructure, .boundGenericTypeAlias, .dependentGenericConformanceRequirement:
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

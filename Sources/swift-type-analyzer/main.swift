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


struct SwiftType: CustomStringConvertible, Hashable, ExpressibleByStringLiteral {
    let fullyQuallifiedName: [String]
    
    init(fullyQuallifiedName: [String]) {
        self.fullyQuallifiedName = fullyQuallifiedName
    }
    
    init(stringLiteral value: StringLiteralType) {
        self.init(fullyQuallifiedName: value.components(separatedBy: "."))
    }
    
    var description: String {
        fullyQuallifiedName.joined(separator: ".")
    }
}

var definitions: [SwiftType: Structure.Kind] = [
    "Swift.Bool": .primitive,
    "Swift.Int": .primitive,
    "Swift.String": .primitive,
    "Swift.Optional": .buildIn,
    "Swift.Array": .buildIn,
]
var usage: [SwiftType: Int] = [:]

traverseStructures(structures: files.flatMap { $0.substructures ?? [] }) { structure in
    do {
        guard let typeId = structure.typeId else {
            return
        }
        let symbol: SwiftSymbol = try parseMangledSwiftSymbol(typeId.rawString)
        
        let swiftTypes = symbol.extractSwiftTypes()
        
        switch structure.kind.isTypeDefinition {
        case .typeDefinition:
            guard let type = swiftTypes.first else {
                fatalError("Missing type in type definition")
            }
            definitions[type] = structure.kind
        case .typeUsage:
            for type in swiftTypes {
                usage[type, default: 0] += 1
            }
        case .other:
            break
        }
    } catch {
        print(error)
    }
}

func getKind(of swiftType: SwiftType) -> Structure.Kind {
    if let kind = definitions[swiftType] {
        return kind
    } else {
        fatalError("Unknown type \(swiftType)")
    }
}

let usageByKind = Dictionary(usage.map { (getKind(of: $0), $1) }, uniquingKeysWith: +)


usageByKind.sorted(by: { $0.1 > $1.1 }).forEach {
    print("\($0.key): \($0.value)")
}


extension SwiftSymbol {
    func extractSwiftTypes() -> [SwiftType] {
        switch kind {
        case .structure, .enum, .protocol, .class, .dependentGenericParamType:
            let nameParts = recursivFlatMap(input: self, valueKeyPath: \.contents.name, recursiveKeyPath: \.children).compactMap { $0 }
            return [SwiftType(fullyQuallifiedName: nameParts)]
        default:
            return extractSwiftTypesOfChildren()
        }
//
//        if let swiftType = extractSwiftType() {
//            return [swiftType] + extractSwiftTypesOfChildren()
//        } else {
//            return extractSwiftTypesOfChildren()
//        }
    }
    
//    private func extractSwiftType() -> SwiftType? {
//        switch kind {
//        case .structure, .enum, .protocol, .class:
//            let nameParts = recursivFlatMap(input: self, valueKeyPath: \.contents.name, recursiveKeyPath: \.children).compactMap { $0 }
//            return SwiftType(fullyQuallifiedName: nameParts)
//        default:
//            return nil
//        }
//    }
    
    private func extractSwiftTypesOfChildren() -> [SwiftType] {
        children.map { $0.extractSwiftTypes() }.reduce([], +)
    }
}

func recursivFlatMap<Input, Output>(input: Input, valueKeyPath: KeyPath<Input, Output>, recursiveKeyPath: KeyPath<Input, [Input]>) -> [Output] {
    [input[keyPath: valueKeyPath]] + input[keyPath: recursiveKeyPath].flatMap {
        recursivFlatMap(input: $0, valueKeyPath: valueKeyPath, recursiveKeyPath: recursiveKeyPath)
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

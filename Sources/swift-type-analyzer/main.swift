import Foundation

let inputURL = URL(fileURLWithPath: "/Users/noahpeeters/Developer/swift-type-analyzer/input")
let outputURL = URL(fileURLWithPath: "/Users/noahpeeters/Developer/swift-type-analyzer/output")

let fileManager = FileManager.default
let structureAnalyzer = StructureAnalyzer()
let jsonEncoder = JSONEncoder()
let csvWriter = CSVWriter()

let inputFiles = try fileManager.contentsOfDirectory(at: inputURL, includingPropertiesForKeys: nil, options: [])

try? fileManager.removeItem(at: outputURL)
try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)

let usageByProject = Dictionary(uniqueKeysWithValues: inputFiles.map { inputFile -> (String, [SwiftType: Int]) in
    let projectName = inputFile.deletingPathExtension().lastPathComponent
    let usage = try! structureAnalyzer.analyzeDocumentation(docURL: inputFile)
    return (projectName, usage)
})

func mergeUsage<C: Collection>(usage: C) -> [SwiftType: Int] where C.Element == [SwiftType: Int] {
    usage.reduce([:]) { $0.merging($1, uniquingKeysWith: +) }
}

func saveUsage(usage: [SwiftType: Int], name: String) {
    func url(forSubtype subtype: String? = nil) -> URL {
        let subtypeInURL = subtype.flatMap { "_\($0)" } ?? ""

        return outputURL
            .appendingPathComponent(name + subtypeInURL)
            .appendingPathExtension("csv")
    }

    func saveUsageWithoutGrouping() {
        let csvColumns: [CSVColumn<(SwiftType, Int)>] = [
            CSVColumn(title: "Module", valueKeyPath: \.0.module),
            CSVColumn(title: "Name", valueKeyPath: \.0.typeNameWithputModule),
            CSVColumn(title: "Kind", valueKeyPath: \.0.kind.rawValue),
            CSVColumn(title: "Count", valueKeyPath: \.1)
        ]

        let csvData = csvWriter.writeCSV(columns: csvColumns, rows: Array(usage))
        try! csvData?.write(to: url())
    }

    func saveUsageByKind() {
        let csvColumns: [CSVColumn<(SwiftType.Kind, Int)>] = [
            CSVColumn(title: "Kind", valueKeyPath: \.0.rawValue),
            CSVColumn(title: "Count", valueKeyPath: \.1)
        ]

        let data = Dictionary(grouping: usage) { $0.0.kind }
            .mapValues { $0.map { $0.value }
            .reduce(0, +) }
            .filter { ![.function, .genericTypeParam, .typealias].contains($0.key) }
        let csvData = csvWriter.writeCSV(columns: csvColumns, rows: Array(data))
        try! csvData?.write(to: url(forSubtype: "ByKind"))
    }

    saveUsageWithoutGrouping()
    saveUsageByKind()
}

func saveUsageOfGroups(group: [String], includeName: String, excludeName: String) {
    let includeList = usageByProject.filter { group.contains($0.key) }
    let excludeList = usageByProject.filter { !group.contains($0.key) }

    print("\(includeName): \(includeList.keys)")
    print("\(excludeName): \(excludeList.keys)")

    saveUsage(usage: mergeUsage(usage: includeList.values), name: includeName)
    saveUsage(usage: mergeUsage(usage: excludeList.values), name: excludeName)

    saveUsage(usage: mergeUsage(usage: includeList.values).filter { !$0.key.isBuildInType }, name: includeName + "_ExcludeSwift")
    saveUsage(usage: mergeUsage(usage: excludeList.values).filter { !$0.key.isBuildInType }, name: excludeName + "_ExcludeSwift")
}

for (name, usage) in usageByProject {
    saveUsage(usage: usage, name: name)
}

saveUsage(usage: mergeUsage(usage: usageByProject.values), name: "total")
saveUsageOfGroups(group: ["mail-ios", "flex-ios"], includeName: "internal", excludeName: "external")
saveUsageOfGroups(group: ["mail-ios", "flex-ios", "shadowsocksX-NG", "iina"], includeName: "app", excludeName: "package")
saveUsageOfGroups(group: ["shadowsocksX-NG", "iina"], includeName: "extern_app", excludeName: "rest")
//
//for inputFile in inputFiles {
//    guard inputFile.pathExtension == "json" else { continue }
//    let outputJSONFile = outputURL.appendingPathComponent(inputFile.lastPathComponent)
//    let outputCSVFile = outputJSONFile.deletingPathExtension().appendingPathExtension("csv")
//
//    print("\(inputFile.path) -> \(outputJSONFile.path)")
//
//    let usage = try structureAnalyzer.analyzeDocumentation(docURL: inputFile)
//    let data = try jsonEncoder.encode(usage)
//    try data.write(to: outputJSONFile)
//
//    let csvData = csvWriter.writeCSV(columns: csvColumns, rows: Array(usage))
//    try csvData?.write(to: outputCSVFile)
//
//    let sum = usage.map { $0.value }.reduce(0, +)
//    let partialSum = usage.filter { $0.key.module == "Swift" }.map { $0.value }.reduce(0, +)
//
//    print(Double(partialSum)/Double(sum))
//}

//extension Dictionary {
//    func mapKeys<OutputKey>(transform: (Key) -> OutputKey) -> [OutputKey: Value] {
//
//        Dictionary.init self.map { (transform($0), $1) }
//    }
//
//    func
//}

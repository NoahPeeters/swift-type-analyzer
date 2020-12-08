import Foundation

let inputURL = URL(fileURLWithPath: "/Users/noahpeeters/Developer/swift-type-analyzer/swift-type-analyzer/input")
let outputURL = URL(fileURLWithPath: "/Users/noahpeeters/Developer/swift-type-analyzer/swift-type-analyzer/output")

let fileManager = FileManager.default
let structureAnalyzer = StructureAnalyzer()
let jsonEncoder = JSONEncoder()
let csvWriter = CSVWriter()

let inputFiles = try fileManager.contentsOfDirectory(at: inputURL, includingPropertiesForKeys: nil, options: [])

try? fileManager.removeItem(at: outputURL)
try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)

let csvColumns: [CSVColumn<(SwiftType, Int)>] = [
    CSVColumn(title: "Module", valueKeyPath: \.0.module),
    CSVColumn(title: "Name", valueKeyPath: \.0.typeNameWithputModule),
    CSVColumn(title: "Kind", valueKeyPath: \.0.kind.rawValue),
    CSVColumn(title: "Count", valueKeyPath: \.1)
]

for inputFile in inputFiles {
    let outputJSONFile = outputURL.appendingPathComponent(inputFile.lastPathComponent)
    let outputCSVFile = outputJSONFile.deletingPathExtension().appendingPathExtension("csv")

    print("\(inputFile.path) -> \(outputJSONFile.path)")

    let usage = try structureAnalyzer.analyzeDocumentation(docURL: inputFile)
    let data = try jsonEncoder.encode(usage)
    try data.write(to: outputJSONFile)

    let csvData = csvWriter.writeCSV(columns: csvColumns, rows: Array(usage))
    try csvData?.write(to: outputCSVFile)
}

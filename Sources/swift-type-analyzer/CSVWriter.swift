//
//  CSVWriter.swift
//  swift-type-analyzer
//
//  Created by Noah Peeters on 29.11.20.
//

import Foundation

struct CSVColumn<RowType> {
    let title: String
    let valueFromRow: (RowType) -> String

    init(title: String, valueFromRow: @escaping (RowType) -> String) {
        self.title = title
        self.valueFromRow = valueFromRow
    }

    init(title: String, valueKeyPath: KeyPath<RowType, String>) {
        self.init(title: title) {
            $0[keyPath: valueKeyPath]
        }
    }

    init(title: String, valueKeyPath: KeyPath<RowType, String?>) {
        self.init(title: title) {
            $0[keyPath: valueKeyPath] ?? ""
        }
    }

    init(title: String, valueKeyPath: KeyPath<RowType, Int>) {
        self.init(title: title) {
            "\($0[keyPath: valueKeyPath])"
        }
    }
}

protocol CSVCellValue {
    var csvCellValue: String { get }
}

class CSVWriter {
    func writeCSV<RowType>(columns: [CSVColumn<RowType>], rows: [RowType]) -> Data? {
        let headerString = columns.map { $0.title }.joined(separator: ",")

        let rowsString = rows.map { row in
            columns.map { column in
                column.valueFromRow(row)
            }.joined(separator: ",")
        }.joined(separator: "\n")

        let csvString = headerString + "\n" + rowsString + "\n"

        return csvString.data(using: .utf8)
    }
}

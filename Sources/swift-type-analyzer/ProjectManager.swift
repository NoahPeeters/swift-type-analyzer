//
//  ProjectManager.swift
//  swift-type-analyzer
//
//  Created by Noah Peeters on 28.11.20.
//

import Foundation

class ProjectManager {
    @discardableResult
    private func shell(command: String) -> Int32 {
        print("Run \(command)")
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["zsh", "-c", command]
        if #available(OSX 10.13, *) {
            task.currentDirectoryURL = projectFolderURL
        } else {
            // Fallback on earlier versions
            fatalError("Unavailable")
        }
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }

    let fileManager = FileManager.default
    let projectFolderURL = URL(fileURLWithPath: "/tmp/swift-type-analyzer-project")
    let docURL = URL(fileURLWithPath: "/tmp/doc.json")

    func generateDoc(gitProjectURL: String, version: String, setupSteps: [String], buildArguments: String) throws -> URL? {
//        try? fileManager.removeItem(at: projectFolderURL)
//        try fileManager.createDirectory(at: projectFolderURL, withIntermediateDirectories: true, attributes: nil)
//
//        shell(command: "git clone \"\(gitProjectURL)\" .")
//        shell(command: "git checkout \"\(version)\"")
//        for setupStep in setupSteps {
//            shell(command: setupStep)
//        }
//
//        shell(command: "/opt/homebrew/bin/sourcekitten doc -- \(buildArguments) > \(docURL.path)")

        return docURL
    }
}

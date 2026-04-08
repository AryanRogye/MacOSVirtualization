//
//  ProcessCreator.swift
//  ComfyGit
//
//  Created by Aryan Rogye on 3/21/26.
//

import Foundation

struct ProcessCreator {
    static func createProcess(
        executableURL: String,
        arguments: [String],
        currentDirectoryURL: URL,
        domain: String
    ) throws -> (Process, Pipe, String) {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(
            fileURLWithPath: executableURL
        )
        process.arguments = arguments
        process.currentDirectoryURL = try validatedDirectoryURL(
            currentDirectoryURL,
            domain: domain
        )
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: domain,
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: output.isEmpty ? "Error." : output]
            )
        }
        return (process, pipe, output)
    }
    
    static func createProcess(
        executableURL: String,
        arguments: [String],
        currentDirectoryPath: String,
        domain: String
    ) throws -> (Process, Pipe, String) {
        try createProcess(
            executableURL: executableURL,
            arguments: arguments,
            currentDirectoryURL: URL(fileURLWithPath: currentDirectoryPath, isDirectory: true),
            domain: domain
        )
    }
    
    private static func validatedDirectoryURL(
        _ url: URL,
        domain: String
    ) throws -> URL {
        guard url.isFileURL else {
            throw NSError(
                domain: domain,
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Repository URL must be a local file URL."]
            )
        }
        
        let standardizedURL = url.standardizedFileURL
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: standardizedURL.path,
            isDirectory: &isDirectory
        )
        
        guard exists, isDirectory.boolValue else {
            throw NSError(
                domain: domain,
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Repository path does not exist or is not a directory."]
            )
        }
        
        return standardizedURL
    }
}

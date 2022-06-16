import Foundation
import PackagePlugin

let pattern = "URL\\s*\\(\\s*safeString\\s*:\\s*\""

@main
struct URLLint: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        guard let target = target as? SourceModuleTarget else { return [] }
        
        return try target.sourceFiles(withSuffix: "swift").compactMap({ sourceFile in
            
            let filePath = URL(fileURLWithPath: sourceFile.path.string)
            let contents = try String(contentsOf: filePath)
            guard let _ = contents.range(of: pattern, options: .regularExpression, range: nil) else {
                return nil
            }
            
            return .buildCommand(
                displayName: "Lint safe URLs from \(sourceFile.path.lastComponent)",
                executable: try context.tool(named: "SafeURLLint").path,
                arguments: [sourceFile.path.string],
                inputFiles: [sourceFile.path]
            )
        })
    }
}

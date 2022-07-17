import Foundation
import PackagePlugin

@main
struct URLLint: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        guard let target = target as? SourceModuleTarget else { return [] }
        return try target.sourceFiles(withSuffix: "swift").compactMap({ sourceFile in
            return .buildCommand(
                displayName: "Lint safe URLs from \(sourceFile.path.lastComponent)",
                executable: try context.tool(named: "SafeURLLintExecutable").path,
                arguments: [sourceFile.path.string], // TODO: Send full list of files
                environment: [:]
            )
        })
    }
}

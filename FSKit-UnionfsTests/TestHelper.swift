//
//  TestHelper.swift
//  FSKit-Unionfs
//
//  Created by Nils Bergmann on 29.11.25.
//

import Foundation
import Command
import OSLog
import Synchronization

class TestHelper {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "TestHelper")
    private let logger = TestHelper.logger // shorthand
    private let cmdRunner = CommandRunner()
    
    public class Branch {
        let path: String
        
        init(_ path: String) {
            self.path = path
        }
    }
    
    private static let killed_fskitd = Mutex(false)

    /// Idfk why fskit sometimes fails to launch the extension after a rebuild, but this fixes it.
    /// Without it writing test would be impossible.
    /// I really hate everything about it
    public static func kill_fskitd() {
        killed_fskitd.withLock { alreadyKilled in
            if alreadyKilled {
                return
            }
            let killScriptSource = """
            do shell script "killall fskitd" with administrator privileges
            """
            let killScript = NSAppleScript(source: killScriptSource)
            let _ = killScript?.executeAndReturnError(nil)
            TestHelper.logger.info("Killed fskitd")
            alreadyKilled = true
        }
    }
    
    /// Mount a test unionfs and add it to local state. If you call `.dispose()`, all mounted filesystems added to its state are getting unmounted.
    /// - Paramters:
    ///     - root: The test root
    ///     - mnt: mnt location relative to test root
    ///     - branches: all branches relative to
    public func mount(with root: URL, mnt: String, branches: [Branch]) async throws -> URL {
        let mntPath = root.appending(path: mnt, directoryHint: .isDirectory)
        
        let branchesAsQueryItem = branches.map({ URLQueryItem(name: "br", value: root.appending(path: $0.path, directoryHint: .isDirectory).path(percentEncoded: false)) })
        
        var mountComponents = URLComponents()
        mountComponents.scheme = "unionfs"
        mountComponents.host = "test"
        mountComponents.queryItems = branchesAsQueryItem

        self.logger.debug("Mount unionfs at \(mntPath.path(percentEncoded: false)). Use url \(mountComponents.url?.absoluteString ?? "nil")")

        let arguments = [
            "mount",
            "-t",
            "Unionfs",
            mountComponents.url!.absoluteString,
            mntPath.path(percentEncoded: false)
        ]
        
        self.logger.debug("Run: \(arguments)")
        
        let stream = self.cmdRunner.run(arguments: arguments)

        for try await output in stream {
            self.logger.debug("output: \(output.string(encoding: .utf8) ?? "nil")")
        }
        
        self.logger.debug("Mount complete.")
        
        mntsToDispose.append(mntPath)
        
        return mntPath
    }
    
    private var mntsToDispose: [URL] = []
    
    /// Force unmount all filesytems mounted with `TestHelper.mount` (async, preferred to avoid QoS inversions).
    public func dispose() async {
        for url in self.mntsToDispose {
            do {
                try await self.cmdRunner.run(arguments: [
                    "umount",
                    "-f",
                    url.path(percentEncoded: false)
                ]).awaitCompletion()
            } catch {
                self.logger.error("Failed to unmount \(url.path(percentEncoded: false), privacy: .public): \(String(describing: error), privacy: .public)")
            }
        }
    }
    
    /// Temporary synchronous wrapper for existing call sites. Prefer awaiting `dispose()` directly.
    /// With this we can simply call `disposeSync()` inside of an `defer` block.
    public func disposeSync(timeoutSeconds: Int = 5) {
        let group = DispatchGroup()
        group.enter()
        let t = Task(priority: Task.currentPriority) {
            await self.dispose()
            group.leave()
        }
        let result = group.wait(timeout: .now() + .seconds(timeoutSeconds))
        if result == .timedOut {
            t.cancel()
        }
    }
}

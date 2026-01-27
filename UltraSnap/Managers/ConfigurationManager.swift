import Foundation
import Cocoa
import os.log

class ConfigurationManager {
    static let shared = ConfigurationManager()

    private let logger = Logger(subsystem: "com.michaelgrady.UltraSnap", category: "ConfigurationManager")
    private let fileManager = FileManager.default

    // File paths
    private var configDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("UltraSnap", isDirectory: true)
    }

    private var configFileURL: URL {
        return configDirectory.appendingPathComponent("display-config.json")
    }

    private var backupFileURL: URL {
        return configDirectory.appendingPathComponent("display-config.backup.json")
    }

    // Cache
    private var cachedConfiguration: ZoneConfiguration?
    private let configQueue = DispatchQueue(label: "com.michaelgrady.UltraSnap.config", attributes: .concurrent)

    private init() {
        createDirectoryIfNeeded()
    }

    // MARK: - Directory Management

    private func createDirectoryIfNeeded() {
        do {
            try fileManager.createDirectory(at: configDirectory, withIntermediateDirectories: true)
            logger.info("Configuration directory ready at: \(self.configDirectory.path)")
        } catch {
            logger.error("Failed to create config directory: \(error.localizedDescription)")
        }
    }

    // MARK: - Load Configuration

    func loadConfiguration() -> ZoneConfiguration {
        return configQueue.sync {
            // Return cached if available
            if let cached = cachedConfiguration {
                return cached
            }

            // Try to load from file
            if let loaded = loadFromFile() {
                cachedConfiguration = loaded
                return loaded
            }

            // Fallback to default
            logger.info("No configuration file found, creating default")
            let defaultConfig = ZoneConfiguration.defaultConfiguration(for: NSScreen.screens)
            saveConfiguration(defaultConfig)
            return defaultConfig
        }
    }

    private func loadFromFile() -> ZoneConfiguration? {
        guard fileManager.fileExists(atPath: configFileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: configFileURL)
            let decoder = JSONDecoder()
            let config = try decoder.decode(ZoneConfiguration.self, from: data)
            logger.info("Loaded configuration from file: \(config.displays.count) displays")
            return config
        } catch {
            logger.error("Failed to load configuration: \(error.localizedDescription)")

            // Try to load backup
            if let backup = loadBackup() {
                logger.info("Restored configuration from backup")
                return backup
            }

            return nil
        }
    }

    private func loadBackup() -> ZoneConfiguration? {
        guard fileManager.fileExists(atPath: backupFileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: backupFileURL)
            let decoder = JSONDecoder()
            return try decoder.decode(ZoneConfiguration.self, from: data)
        } catch {
            logger.error("Failed to load backup: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Save Configuration

    func saveConfiguration(_ config: ZoneConfiguration) {
        configQueue.async(flags: .barrier) {
            do {
                // Backup existing file
                if self.fileManager.fileExists(atPath: self.configFileURL.path) {
                    try? self.fileManager.removeItem(at: self.backupFileURL)
                    try? self.fileManager.copyItem(at: self.configFileURL, to: self.backupFileURL)
                }

                // Encode and write
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(config)
                try data.write(to: self.configFileURL, options: .atomic)

                self.cachedConfiguration = config
                self.logger.info("Saved configuration: \(config.displays.count) displays")
            } catch {
                self.logger.error("Failed to save configuration: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Preset Management

    func getPreset(for displayIdentifier: DisplayIdentifier) -> ZonePreset {
        let config = loadConfiguration()
        return config.preset(for: displayIdentifier) ?? .thirds
    }

    func setPreset(_ preset: ZonePreset, for displayIdentifier: DisplayIdentifier) {
        let config = loadConfiguration()
        let updated = config.updatingPreset(for: displayIdentifier, to: preset)
        saveConfiguration(updated)
    }

    // MARK: - Reset

    func resetToDefaults() {
        configQueue.async(flags: .barrier) {
            let defaultConfig = ZoneConfiguration.defaultConfiguration(for: NSScreen.screens)
            self.saveConfiguration(defaultConfig)
            self.logger.info("Reset configuration to defaults")
        }
    }
}

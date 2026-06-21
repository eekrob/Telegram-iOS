import Foundation
import Postbox
import SwiftSignalKit

/// Account-specific AyuGram preferences consumed by TelegramCore operations.
public struct AyuSettings: Codable, Equatable {
    public var sendReadReceipts: Bool
    public var sendOnlineStatus: Bool
    public var sendUploadProgress: Bool
    public var sendOfflineAfterOnline: Bool

    public var markReadAfterSend: Bool
    public var useScheduledMessages: Bool

    public var saveDeletedMessages: Bool
    public var saveMessageHistory: Bool
    public var saveMedia: Bool
    public var saveFormatting: Bool
    public var saveReactions: Bool
    public var saveForBots: Bool

    public var deletedMessageMark: String
    public var editedMessageMark: String

    public static let defaultSettings = AyuSettings(
        sendReadReceipts: true,
        sendOnlineStatus: true,
        sendUploadProgress: true,
        sendOfflineAfterOnline: false,
        markReadAfterSend: true,
        useScheduledMessages: false,
        saveDeletedMessages: true,
        saveMessageHistory: true,
        saveMedia: true,
        saveFormatting: true,
        saveReactions: true,
        saveForBots: true,
        deletedMessageMark: "🧹",
        editedMessageMark: "edited"
    )

    public var isGhostModeEnabled: Bool {
        return !self.sendReadReceipts
            && !self.sendOnlineStatus
            && !self.sendUploadProgress
            && self.sendOfflineAfterOnline
    }

    public init(
        sendReadReceipts: Bool,
        sendOnlineStatus: Bool,
        sendUploadProgress: Bool,
        sendOfflineAfterOnline: Bool,
        markReadAfterSend: Bool,
        useScheduledMessages: Bool,
        saveDeletedMessages: Bool,
        saveMessageHistory: Bool,
        saveMedia: Bool,
        saveFormatting: Bool,
        saveReactions: Bool,
        saveForBots: Bool,
        deletedMessageMark: String,
        editedMessageMark: String
    ) {
        self.sendReadReceipts = sendReadReceipts
        self.sendOnlineStatus = sendOnlineStatus
        self.sendUploadProgress = sendUploadProgress
        self.sendOfflineAfterOnline = sendOfflineAfterOnline
        self.markReadAfterSend = markReadAfterSend
        self.useScheduledMessages = useScheduledMessages
        self.saveDeletedMessages = saveDeletedMessages
        self.saveMessageHistory = saveMessageHistory
        self.saveMedia = saveMedia
        self.saveFormatting = saveFormatting
        self.saveReactions = saveReactions
        self.saveForBots = saveForBots
        self.deletedMessageMark = deletedMessageMark
        self.editedMessageMark = editedMessageMark
    }

    public init(from decoder: Decoder) throws {
        let defaults = AyuSettings.defaultSettings
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        self.sendReadReceipts = try container.decodeIfPresent(Bool.self, forKey: "sendReadReceipts") ?? defaults.sendReadReceipts
        self.sendOnlineStatus = try container.decodeIfPresent(Bool.self, forKey: "sendOnlineStatus") ?? defaults.sendOnlineStatus
        self.sendUploadProgress = try container.decodeIfPresent(Bool.self, forKey: "sendUploadProgress") ?? defaults.sendUploadProgress
        self.sendOfflineAfterOnline = try container.decodeIfPresent(Bool.self, forKey: "sendOfflineAfterOnline") ?? defaults.sendOfflineAfterOnline
        self.markReadAfterSend = try container.decodeIfPresent(Bool.self, forKey: "markReadAfterSend") ?? defaults.markReadAfterSend
        self.useScheduledMessages = try container.decodeIfPresent(Bool.self, forKey: "useScheduledMessages") ?? defaults.useScheduledMessages
        self.saveDeletedMessages = try container.decodeIfPresent(Bool.self, forKey: "saveDeletedMessages") ?? defaults.saveDeletedMessages
        self.saveMessageHistory = try container.decodeIfPresent(Bool.self, forKey: "saveMessageHistory") ?? defaults.saveMessageHistory
        self.saveMedia = try container.decodeIfPresent(Bool.self, forKey: "saveMedia") ?? defaults.saveMedia
        self.saveFormatting = try container.decodeIfPresent(Bool.self, forKey: "saveFormatting") ?? defaults.saveFormatting
        self.saveReactions = try container.decodeIfPresent(Bool.self, forKey: "saveReactions") ?? defaults.saveReactions
        self.saveForBots = try container.decodeIfPresent(Bool.self, forKey: "saveForBots") ?? defaults.saveForBots
        self.deletedMessageMark = try container.decodeIfPresent(String.self, forKey: "deletedMessageMark") ?? defaults.deletedMessageMark
        self.editedMessageMark = try container.decodeIfPresent(String.self, forKey: "editedMessageMark") ?? defaults.editedMessageMark
    }

    public func withGhostModeEnabled(_ enabled: Bool) -> AyuSettings {
        var result = self
        result.sendReadReceipts = !enabled
        result.sendOnlineStatus = !enabled
        result.sendUploadProgress = !enabled
        result.sendOfflineAfterOnline = enabled
        return result
    }
}

public func getAyuSettings(transaction: Transaction) -> AyuSettings {
    return transaction.getPreferencesEntry(key: PreferencesKeys.ayuSettings)?.get(AyuSettings.self) ?? AyuSettings.defaultSettings
}

public func ayuSettings(postbox: Postbox) -> Signal<AyuSettings, NoError> {
    return postbox.preferencesView(keys: [PreferencesKeys.ayuSettings])
    |> map { view -> AyuSettings in
        return view.values[PreferencesKeys.ayuSettings]?.get(AyuSettings.self) ?? AyuSettings.defaultSettings
    }
    |> distinctUntilChanged
}

public func updateAyuSettingsInteractively(
    postbox: Postbox,
    _ f: @escaping (AyuSettings) -> AyuSettings
) -> Signal<Never, NoError> {
    return postbox.transaction { transaction -> Void in
        transaction.updatePreferencesEntry(key: PreferencesKeys.ayuSettings, { entry in
            let current = entry?.get(AyuSettings.self) ?? AyuSettings.defaultSettings
            return PreferencesEntry(f(current))
        })
    }
    |> ignoreValues
}

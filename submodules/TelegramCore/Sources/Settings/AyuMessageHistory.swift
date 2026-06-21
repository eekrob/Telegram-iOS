import Foundation
import Postbox
import SwiftSignalKit

public enum AyuMessageRevisionKind: Int32, Equatable {
    case edited = 0
    case deleted = 1
}

public struct AyuMessageRevision: Codable, Equatable {
    public let kind: AyuMessageRevisionKind
    public let capturedAt: Int32
    public let messageTimestamp: Int32
    public let authorId: Int64?
    public let threadId: Int64?
    public let text: String
    public let mediaKinds: [String]
    public let isIncoming: Bool
    public let displayMark: String

    private enum CodingKeys: String, CodingKey {
        case kind
        case capturedAt
        case messageTimestamp
        case authorId
        case threadId
        case text
        case mediaKinds
        case isIncoming
        case displayMark
    }

    public init(
        kind: AyuMessageRevisionKind,
        capturedAt: Int32,
        messageTimestamp: Int32,
        authorId: Int64?,
        threadId: Int64?,
        text: String,
        mediaKinds: [String],
        isIncoming: Bool,
        displayMark: String
    ) {
        self.kind = kind
        self.capturedAt = capturedAt
        self.messageTimestamp = messageTimestamp
        self.authorId = authorId
        self.threadId = threadId
        self.text = text
        self.mediaKinds = mediaKinds
        self.isIncoming = isIncoming
        self.displayMark = displayMark
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawKind = try container.decode(Int32.self, forKey: .kind)
        guard let kind = AyuMessageRevisionKind(rawValue: rawKind) else {
            throw DecodingError.dataCorruptedError(
                forKey: .kind,
                in: container,
                debugDescription: "Unknown Ayu message revision kind: \(rawKind)"
            )
        }
        self.kind = kind
        self.capturedAt = try container.decode(Int32.self, forKey: .capturedAt)
        self.messageTimestamp = try container.decode(Int32.self, forKey: .messageTimestamp)
        self.authorId = try container.decodeIfPresent(Int64.self, forKey: .authorId)
        self.threadId = try container.decodeIfPresent(Int64.self, forKey: .threadId)
        self.text = try container.decode(String.self, forKey: .text)
        self.mediaKinds = try container.decode([String].self, forKey: .mediaKinds)
        self.isIncoming = try container.decode(Bool.self, forKey: .isIncoming)
        self.displayMark = try container.decodeIfPresent(String.self, forKey: .displayMark) ?? ""
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.kind.rawValue, forKey: .kind)
        try container.encode(self.capturedAt, forKey: .capturedAt)
        try container.encode(self.messageTimestamp, forKey: .messageTimestamp)
        try container.encodeIfPresent(self.authorId, forKey: .authorId)
        try container.encodeIfPresent(self.threadId, forKey: .threadId)
        try container.encode(self.text, forKey: .text)
        try container.encode(self.mediaKinds, forKey: .mediaKinds)
        try container.encode(self.isIncoming, forKey: .isIncoming)
        try container.encode(self.displayMark, forKey: .displayMark)
    }
}

public struct AyuMessageHistory: Codable, Equatable {
    public var revisions: [AyuMessageRevision]

    public static let empty = AyuMessageHistory(revisions: [])
}

public struct AyuMessageHistoryReference: Codable, Equatable {
    public let peerId: Int64
    public let messageNamespace: Int32
    public let messageId: Int32
    public let lastCapturedAt: Int32
    public let isDeleted: Bool
    public let lastText: String
    public let revisionCount: Int32

    public var id: MessageId {
        return MessageId(peerId: PeerId(self.peerId), namespace: self.messageNamespace, id: self.messageId)
    }
}

private struct AyuMessageHistoryIndex: Codable, Equatable {
    var items: [AyuMessageHistoryReference]

    static let empty = AyuMessageHistoryIndex(items: [])
}

private let ayuMaxRevisionsPerMessage = 100
private let ayuMaxIndexedMessages = 10_000

private let ayuMessageHistoryIndexEntryId: ItemCacheEntryId = {
    let key = ValueBoxKey(length: 1)
    key.setInt8(0, value: 0)
    return ItemCacheEntryId(collectionId: Namespaces.CachedItemCollection.ayuMessageHistory, key: key)
}()

private func ayuMessageHistoryEntryId(_ messageId: MessageId) -> ItemCacheEntryId {
    let key = ValueBoxKey(length: 16)
    key.setInt64(0, value: messageId.peerId.toInt64())
    key.setInt32(8, value: messageId.namespace)
    key.setInt32(12, value: messageId.id)
    return ItemCacheEntryId(collectionId: Namespaces.CachedItemCollection.ayuMessageHistory, key: key)
}

func ayuMediaKinds(_ media: [Media]) -> [String] {
    return media.map { item -> String in
        if item is TelegramMediaImage {
            return "image"
        } else if item is TelegramMediaFile {
            return "file"
        } else if item is TelegramMediaMap {
            return "location"
        } else if item is TelegramMediaContact {
            return "contact"
        } else if item is TelegramMediaPoll {
            return "poll"
        } else if item is TelegramMediaDice {
            return "dice"
        } else if item is TelegramMediaAction {
            return "action"
        } else if item is TelegramMediaWebpage {
            return "webpage"
        } else {
            return String(describing: type(of: item))
        }
    }
}

func storeAyuMessageRevision(transaction: Transaction, message: Message, kind: AyuMessageRevisionKind) {
    let settings = getAyuSettings(transaction: transaction)
    if !settings.saveForBots, let author = message.author as? TelegramUser, author.botInfo != nil {
        return
    }
    switch kind {
    case .edited:
        if !settings.saveMessageHistory {
            return
        }
    case .deleted:
        if !settings.saveDeletedMessages {
            return
        }
    }

    let entryId = ayuMessageHistoryEntryId(message.id)
    var history = transaction.retrieveItemCacheEntry(id: entryId)?.get(AyuMessageHistory.self) ?? .empty
    let revision = AyuMessageRevision(
        kind: kind,
        capturedAt: Int32(Date().timeIntervalSince1970),
        messageTimestamp: message.timestamp,
        authorId: message.author?.id.toInt64(),
        threadId: message.threadId,
        text: message.text,
        mediaKinds: ayuMediaKinds(message.media),
        isIncoming: message.flags.contains(.Incoming),
        displayMark: kind == .deleted ? settings.deletedMessageMark : settings.editedMessageMark
    )

    if let last = history.revisions.last {
        if last.kind == revision.kind
            && last.messageTimestamp == revision.messageTimestamp
            && last.authorId == revision.authorId
            && last.threadId == revision.threadId
            && last.text == revision.text
            && last.mediaKinds == revision.mediaKinds
            && last.isIncoming == revision.isIncoming {
            return
        }
    }
    history.revisions.append(revision)
    if history.revisions.count > ayuMaxRevisionsPerMessage {
        history.revisions.removeFirst(history.revisions.count - ayuMaxRevisionsPerMessage)
    }
    if let entry = CodableEntry(history) {
        transaction.putItemCacheEntry(id: entryId, entry: entry)
    }

    var index = transaction.retrieveItemCacheEntry(id: ayuMessageHistoryIndexEntryId)?.get(AyuMessageHistoryIndex.self) ?? .empty
    let previousReference = index.items.first(where: { $0.id == message.id })
    index.items.removeAll(where: { $0.id == message.id })
    index.items.append(AyuMessageHistoryReference(
        peerId: message.id.peerId.toInt64(),
        messageNamespace: message.id.namespace,
        messageId: message.id.id,
        lastCapturedAt: revision.capturedAt,
        isDeleted: kind == .deleted || previousReference?.isDeleted == true,
        lastText: revision.text,
        revisionCount: Int32(clamping: history.revisions.count)
    ))
    if index.items.count > ayuMaxIndexedMessages {
        index.items.removeFirst(index.items.count - ayuMaxIndexedMessages)
    }
    if let entry = CodableEntry(index) {
        transaction.putItemCacheEntry(id: ayuMessageHistoryIndexEntryId, entry: entry)
    }
}

/// Keeps a server-deleted message in the local Postbox and appends AyuGram's
/// configured deletion marker. Returns `true` when normal deletion should be
/// skipped for this message.
func retainAyuDeletedMessage(transaction: Transaction, message: Message) -> Bool {
    let settings = getAyuSettings(transaction: transaction)
    if !settings.saveDeletedMessages {
        return false
    }
    if !settings.saveForBots, let author = message.author as? TelegramUser, author.botInfo != nil {
        return false
    }

    let configuredMark = settings.deletedMessageMark.trimmingCharacters(in: .whitespacesAndNewlines)
    let mark = configuredMark.isEmpty ? "🧹" : configuredMark
    let markedSuffix = "\n\(mark)"
    if message.text == mark || message.text.hasSuffix(markedSuffix) {
        return true
    }

    storeAyuMessageRevision(transaction: transaction, message: message, kind: .deleted)
    transaction.updateMessage(message.id, update: { currentMessage in
        let updatedText = currentMessage.text.isEmpty ? mark : currentMessage.text + markedSuffix
        return .update(StoreMessage(
            id: currentMessage.id,
            customStableId: nil,
            globallyUniqueId: currentMessage.globallyUniqueId,
            groupingKey: currentMessage.groupingKey,
            threadId: currentMessage.threadId,
            timestamp: currentMessage.timestamp,
            flags: StoreMessageFlags(currentMessage.flags),
            tags: currentMessage.tags,
            globalTags: currentMessage.globalTags,
            localTags: currentMessage.localTags,
            forwardInfo: currentMessage.forwardInfo.flatMap(StoreMessageForwardInfo.init),
            authorId: currentMessage.author?.id,
            text: updatedText,
            attributes: currentMessage.attributes,
            media: currentMessage.media
        ))
    })
    return true
}

public func ayuMessageHistory(postbox: Postbox, messageId: MessageId) -> Signal<AyuMessageHistory, NoError> {
    let key = PostboxViewKey.cachedItem(ayuMessageHistoryEntryId(messageId))
    return postbox.combinedView(keys: [key])
    |> map { views -> AyuMessageHistory in
        return (views.views[key] as? CachedItemView)?.value?.get(AyuMessageHistory.self) ?? .empty
    }
    |> distinctUntilChanged
}

public func clearAyuMessageHistory(postbox: Postbox, messageId: MessageId) -> Signal<Never, NoError> {
    return postbox.transaction { transaction -> Void in
        transaction.removeItemCacheEntry(id: ayuMessageHistoryEntryId(messageId))
        var index = transaction.retrieveItemCacheEntry(id: ayuMessageHistoryIndexEntryId)?.get(AyuMessageHistoryIndex.self) ?? .empty
        index.items.removeAll(where: { $0.id == messageId })
        if let entry = CodableEntry(index) {
            transaction.putItemCacheEntry(id: ayuMessageHistoryIndexEntryId, entry: entry)
        }
    }
    |> ignoreValues
}

public func ayuMessageHistoryIndex(postbox: Postbox) -> Signal<[AyuMessageHistoryReference], NoError> {
    let key = PostboxViewKey.cachedItem(ayuMessageHistoryIndexEntryId)
    return postbox.combinedView(keys: [key])
    |> map { views -> [AyuMessageHistoryReference] in
        let index = (views.views[key] as? CachedItemView)?.value?.get(AyuMessageHistoryIndex.self) ?? .empty
        return Array(index.items.reversed())
    }
    |> distinctUntilChanged
}

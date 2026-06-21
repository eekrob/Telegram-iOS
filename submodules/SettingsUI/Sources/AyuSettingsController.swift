import Foundation
import UIKit
import AccountContext
import Display
import ItemListUI
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData

private final class AyuSettingsControllerArguments {
    let update: (@escaping (inout AyuSettings) -> Void) -> Void
    let openHistory: () -> Void

    init(update: @escaping (@escaping (inout AyuSettings) -> Void) -> Void, openHistory: @escaping () -> Void) {
        self.update = update
        self.openHistory = openHistory
    }
}

private enum AyuSettingsSection: Int32 {
    case ghost
    case history
}

private enum AyuSettingsEntry: ItemListNodeEntry {
    case ghostHeader
    case ghostMode(Bool)
    case sendReadReceipts(Bool)
    case sendOnlineStatus(Bool)
    case sendUploadProgress(Bool)
    case sendOfflineAfterOnline(Bool)
    case ghostFooter

    case historyHeader
    case historyIndex(Int)
    case saveDeletedMessages(Bool)
    case saveMessageHistory(Bool)
    case saveMedia(Bool)
    case saveFormatting(Bool)
    case saveReactions(Bool)
    case saveForBots(Bool)
    case historyFooter

    var section: ItemListSectionId {
        switch self {
        case .ghostHeader, .ghostMode, .sendReadReceipts, .sendOnlineStatus, .sendUploadProgress, .sendOfflineAfterOnline, .ghostFooter:
            return AyuSettingsSection.ghost.rawValue
        case .historyHeader, .historyIndex, .saveDeletedMessages, .saveMessageHistory, .saveMedia, .saveFormatting, .saveReactions, .saveForBots, .historyFooter:
            return AyuSettingsSection.history.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .ghostHeader:
            return 0
        case .ghostMode:
            return 1
        case .sendReadReceipts:
            return 2
        case .sendOnlineStatus:
            return 3
        case .sendUploadProgress:
            return 4
        case .sendOfflineAfterOnline:
            return 5
        case .ghostFooter:
            return 6
        case .historyHeader:
            return 7
        case .historyIndex:
            return 8
        case .saveDeletedMessages:
            return 9
        case .saveMessageHistory:
            return 10
        case .saveMedia:
            return 11
        case .saveFormatting:
            return 12
        case .saveReactions:
            return 13
        case .saveForBots:
            return 14
        case .historyFooter:
            return 15
        }
    }

    static func < (lhs: AyuSettingsEntry, rhs: AyuSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuSettingsControllerArguments
        switch self {
        case .ghostHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "GHOST MODE", sectionId: self.section)
        case let .ghostMode(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Ghost mode", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { settings in
                    settings = settings.withGhostModeEnabled(value)
                }
            })
        case let .sendReadReceipts(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Send read receipts", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.sendReadReceipts = value }
            })
        case let .sendOnlineStatus(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Send online status", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.sendOnlineStatus = value }
            })
        case let .sendUploadProgress(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Send upload progress", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.sendUploadProgress = value }
            })
        case let .sendOfflineAfterOnline(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Send offline after online", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.sendOfflineAfterOnline = value }
            })
        case .ghostFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Ghost mode keeps read state local and suppresses presence, typing, upload progress, and supported read-receipt requests."), sectionId: self.section)
        case .historyHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "MESSAGE HISTORY", sectionId: self.section)
        case let .historyIndex(count):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Saved history", label: "\(count)", labelStyle: .detailText, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openHistory()
            })
        case let .saveDeletedMessages(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Save deleted messages", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.saveDeletedMessages = value }
            })
        case let .saveMessageHistory(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Save edit history", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.saveMessageHistory = value }
            })
        case let .saveMedia(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Save media", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.saveMedia = value }
            })
        case let .saveFormatting(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Save formatting", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.saveFormatting = value }
            })
        case let .saveReactions(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Save reactions", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.saveReactions = value }
            })
        case let .saveForBots(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Save messages from bots", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.saveForBots = value }
            })
        case .historyFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Saved revisions will remain local to this device unless AyuSync support is enabled later."), sectionId: self.section)
        }
    }
}

private func ayuSettingsEntries(settings: AyuSettings, historyCount: Int) -> [AyuSettingsEntry] {
    return [
        .ghostHeader,
        .ghostMode(settings.isGhostModeEnabled),
        .sendReadReceipts(settings.sendReadReceipts),
        .sendOnlineStatus(settings.sendOnlineStatus),
        .sendUploadProgress(settings.sendUploadProgress),
        .sendOfflineAfterOnline(settings.sendOfflineAfterOnline),
        .ghostFooter,
        .historyHeader,
        .historyIndex(historyCount),
        .saveDeletedMessages(settings.saveDeletedMessages),
        .saveMessageHistory(settings.saveMessageHistory),
        .saveMedia(settings.saveMedia),
        .saveFormatting(settings.saveFormatting),
        .saveReactions(settings.saveReactions),
        .saveForBots(settings.saveForBots),
        .historyFooter
    ]
}

public func ayuSettingsController(context: AccountContext) -> ViewController {
    var pushImpl: ((ViewController) -> Void)?
    let arguments = AyuSettingsControllerArguments(update: { f in
        let _ = updateAyuSettingsInteractively(postbox: context.account.postbox, { current in
            var updated = current
            f(&updated)
            return updated
        }).start()
    }, openHistory: {
        pushImpl?(ayuMessageHistoryController(context: context))
    })

    let signal = combineLatest(queue: .mainQueue(), context.sharedContext.presentationData, ayuSettings(postbox: context.account.postbox), ayuMessageHistoryIndex(postbox: context.account.postbox))
    |> map { presentationData, settings, historyIndex -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("AyuGram"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: ayuSettingsEntries(settings: settings, historyCount: historyIndex.count),
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushImpl = { [weak controller] next in
        controller?.push(next)
    }
    return controller
}

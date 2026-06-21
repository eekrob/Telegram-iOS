import Foundation
import UIKit
import AccountContext
import Display
import ItemListUI
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData

private func ayuLocalized(_ presentationData: ItemListPresentationData, english: String, russian: String) -> String {
    if presentationData.strings.primaryComponent.languageCode.lowercased().hasPrefix("ru") {
        return russian
    }
    return english
}

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
    case deletedMessageMark(String)
    case editedMessageMark(String)
    case historyFooter

    var section: ItemListSectionId {
        switch self {
        case .ghostHeader, .ghostMode, .sendReadReceipts, .sendOnlineStatus, .sendUploadProgress, .sendOfflineAfterOnline, .ghostFooter:
            return AyuSettingsSection.ghost.rawValue
        case .historyHeader, .historyIndex, .saveDeletedMessages, .saveMessageHistory, .saveMedia, .saveFormatting, .saveReactions, .saveForBots, .deletedMessageMark, .editedMessageMark, .historyFooter:
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
            return 17
        case .deletedMessageMark:
            return 15
        case .editedMessageMark:
            return 16
        }
    }

    static func < (lhs: AyuSettingsEntry, rhs: AyuSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuSettingsControllerArguments
        switch self {
        case .ghostHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: ayuLocalized(presentationData, english: "GHOST MODE", russian: "РЕЖИМ ПРИЗРАКА"), sectionId: self.section)
        case let .ghostMode(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: ayuLocalized(presentationData, english: "Ghost mode", russian: "Режим Призрака"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { settings in
                    settings = settings.withGhostModeEnabled(value)
                }
            })
        case let .sendReadReceipts(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: ayuLocalized(presentationData, english: "Send read receipts", russian: "Отправлять «прочитано»"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.sendReadReceipts = value }
            })
        case let .sendOnlineStatus(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: ayuLocalized(presentationData, english: "Send online status", russian: "Отправлять статус «в сети»"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.sendOnlineStatus = value }
            })
        case let .sendUploadProgress(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: ayuLocalized(presentationData, english: "Send upload progress", russian: "Отправлять прогресс загрузки"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.sendUploadProgress = value }
            })
        case let .sendOfflineAfterOnline(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: ayuLocalized(presentationData, english: "Send offline after online", russian: "Отправлять «не в сети» после онлайна"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.sendOfflineAfterOnline = value }
            })
        case .ghostFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain(ayuLocalized(presentationData, english: "Ghost mode keeps read state local and suppresses presence, typing, upload progress, and supported read-receipt requests.", russian: "Режим Призрака сохраняет прочтение локально и скрывает онлайн, набор текста, загрузку файлов и поддерживаемые подтверждения прочтения.")), sectionId: self.section)
        case .historyHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: ayuLocalized(presentationData, english: "MESSAGE HISTORY", russian: "ИСТОРИЯ СООБЩЕНИЙ"), sectionId: self.section)
        case let .historyIndex(count):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: ayuLocalized(presentationData, english: "Saved history", russian: "Сохранённая история"), label: "\(count)", labelStyle: .detailText, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openHistory()
            })
        case let .saveDeletedMessages(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: ayuLocalized(presentationData, english: "Save deleted messages", russian: "Сохранять удалённые сообщения"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.saveDeletedMessages = value }
            })
        case let .saveMessageHistory(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: ayuLocalized(presentationData, english: "Save edit history", russian: "Сохранять историю изменений"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.saveMessageHistory = value }
            })
        case let .saveMedia(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: ayuLocalized(presentationData, english: "Save media", russian: "Сохранять медиа"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.saveMedia = value }
            })
        case let .saveFormatting(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: ayuLocalized(presentationData, english: "Save formatting", russian: "Сохранять форматирование"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.saveFormatting = value }
            })
        case let .saveReactions(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: ayuLocalized(presentationData, english: "Save reactions", russian: "Сохранять реакции"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.saveReactions = value }
            })
        case let .saveForBots(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: ayuLocalized(presentationData, english: "Save messages from bots", russian: "Сохранять сообщения ботов"), value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.update { $0.saveForBots = value }
            })
        case let .deletedMessageMark(value):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: NSAttributedString(), text: value, placeholder: ayuLocalized(presentationData, english: "Deleted message mark", russian: "Пометка удалённого сообщения"), type: .regular(capitalization: false, autocorrection: false), sectionId: self.section, textUpdated: { value in
                arguments.update { $0.deletedMessageMark = value }
            }, action: {})
        case let .editedMessageMark(value):
            return ItemListSingleLineInputItem(presentationData: presentationData, systemStyle: .glass, title: NSAttributedString(), text: value, placeholder: ayuLocalized(presentationData, english: "Edited message mark", russian: "Пометка изменённого сообщения"), type: .regular(capitalization: false, autocorrection: false), sectionId: self.section, textUpdated: { value in
                arguments.update { $0.editedMessageMark = value }
            }, action: {})
        case .historyFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain(ayuLocalized(presentationData, english: "Saved revisions remain local to this device.", russian: "Сохранённые версии остаются только на этом устройстве.")), sectionId: self.section)
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
        .deletedMessageMark(settings.deletedMessageMark),
        .editedMessageMark(settings.editedMessageMark),
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

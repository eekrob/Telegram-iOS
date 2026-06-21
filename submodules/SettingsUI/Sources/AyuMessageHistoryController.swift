import Foundation
import UIKit
import AccountContext
import Display
import ItemListUI
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData

private final class AyuHistoryListArguments {
    let open: (AyuMessageHistoryReference) -> Void

    init(open: @escaping (AyuMessageHistoryReference) -> Void) {
        self.open = open
    }
}

private enum AyuHistoryListEntry: ItemListNodeEntry {
    case empty
    case message(Int32, AyuMessageHistoryReference)

    var section: ItemListSectionId {
        return 0
    }

    var stableId: Int32 {
        switch self {
        case .empty:
            return 0
        case let .message(index, _):
            return index + 1
        }
    }

    static func < (lhs: AyuHistoryListEntry, rhs: AyuHistoryListEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuHistoryListArguments
        switch self {
        case .empty:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Edited and deleted message snapshots will appear here."), sectionId: self.section)
        case let .message(_, reference):
            let title = reference.isDeleted ? "Deleted message" : "Edited message"
            let text = reference.lastText.isEmpty ? "\(reference.id)" : reference.lastText
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                label: text,
                labelStyle: .multilineDetailText,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    arguments.open(reference)
                }
            )
        }
    }
}

private func ayuHistoryListEntries(_ references: [AyuMessageHistoryReference]) -> [AyuHistoryListEntry] {
    if references.isEmpty {
        return [.empty]
    }
    return references.enumerated().map { index, reference in
        return .message(Int32(clamping: index), reference)
    }
}

private enum AyuHistoryDetailEntry: ItemListNodeEntry {
    case empty
    case revision(Int32, AyuMessageRevision)

    var section: ItemListSectionId {
        return 0
    }

    var stableId: Int32 {
        switch self {
        case .empty:
            return 0
        case let .revision(index, _):
            return index + 1
        }
    }

    static func < (lhs: AyuHistoryDetailEntry, rhs: AyuHistoryDetailEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        switch self {
        case .empty:
            return ItemListTextItem(presentationData: presentationData, text: .plain("No saved revisions."), sectionId: self.section)
        case let .revision(_, revision):
            let event = revision.kind == .deleted ? "Deleted" : "Edited"
            let date = DateFormatter.localizedString(from: Date(timeIntervalSince1970: TimeInterval(revision.capturedAt)), dateStyle: .short, timeStyle: .short)
            var detail = revision.text
            if detail.isEmpty && !revision.mediaKinds.isEmpty {
                detail = revision.mediaKinds.joined(separator: ", ")
            }
            if detail.isEmpty {
                detail = "Empty message"
            }
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "\(event) - \(date)",
                label: detail,
                labelStyle: .multilineDetailText,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: nil
            )
        }
    }
}

private func ayuHistoryDetailEntries(_ history: AyuMessageHistory) -> [AyuHistoryDetailEntry] {
    if history.revisions.isEmpty {
        return [.empty]
    }
    return history.revisions.reversed().enumerated().map { index, revision in
        return .revision(Int32(clamping: index), revision)
    }
}

private func ayuMessageHistoryDetailController(context: AccountContext, reference: AyuMessageHistoryReference) -> ViewController {
    let signal = combineLatest(
        queue: .mainQueue(),
        context.sharedContext.presentationData,
        ayuMessageHistory(postbox: context.account.postbox, messageId: reference.id)
    )
    |> map { presentationData, history -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Message History"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: ayuHistoryDetailEntries(history),
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, ()))
    }
    return ItemListController(context: context, state: signal)
}

public func ayuMessageHistoryController(context: AccountContext) -> ViewController {
    var pushImpl: ((ViewController) -> Void)?
    let arguments = AyuHistoryListArguments(open: { reference in
        pushImpl?(ayuMessageHistoryDetailController(context: context, reference: reference))
    })
    let signal = combineLatest(
        queue: .mainQueue(),
        context.sharedContext.presentationData,
        ayuMessageHistoryIndex(postbox: context.account.postbox)
    )
    |> map { presentationData, references -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Saved History"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: ayuHistoryListEntries(references),
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

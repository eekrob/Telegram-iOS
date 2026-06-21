import Foundation
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
//import PhoneNumberFormat

private let ayuGramTeamUserIds: Set<Int64> = [
    963080346, 1282540315, 1374434073, 388099852, 1972014627,
    168769611, 480000401, 5307590670, 639891381, 1773117711,
    5330087923, 666154369, 139303278, 778327202, 963494570,
    238292700, 1795176335
]

private let ayuGramOfficialChannelIds: Set<Int64> = [
    1905581924, 1794457129, 1434550607
]

private extension EnginePeer {
    var hasAyuGramBadge: Bool {
        switch self {
        case let .user(user):
            return ayuGramTeamUserIds.contains(user.id.id._internalGetInt64Value())
        case let .legacyGroup(group):
            return ayuGramOfficialChannelIds.contains(group.id.id._internalGetInt64Value())
        case let .channel(channel):
            return ayuGramOfficialChannelIds.contains(channel.id.id._internalGetInt64Value())
        case .secretChat:
            return false
        }
    }

    func withAyuGramBadge(_ title: String) -> String {
        return self.hasAyuGramBadge && !title.isEmpty ? title + " ✦" : title
    }
}

public extension EnginePeer {
    var compactDisplayTitle: String {
        switch self {
        case let .user(user):
            if let firstName = user.firstName, !firstName.isEmpty {
                return firstName
            } else if let lastName = user.lastName, !lastName.isEmpty {
                return lastName
            } else if let _ = user.phone {
                return "" //formatPhoneNumber("+\(phone)")
            } else {
                return "Deleted Account"
            }
        case let .legacyGroup(group):
            return group.title
        case let .channel(channel):
            return channel.title
        case .secretChat:
            return ""
        }
    }

    func displayTitle(strings: PresentationStrings, displayOrder: PresentationPersonNameOrder) -> String {
        let title: String
        switch self {
        case let .user(user):
            if user.id.isReplies {
                title = strings.DialogList_Replies
            } else if let firstName = user.firstName, !firstName.isEmpty {
                if let lastName = user.lastName, !lastName.isEmpty {
                    switch displayOrder {
                    case .firstLast:
                        title = "\(firstName) \(lastName)"
                    case .lastFirst:
                        title = "\(lastName) \(firstName)"
                    }
                } else {
                    title = firstName
                }
            } else if let lastName = user.lastName, !lastName.isEmpty {
                title = lastName
            } else if let _ = user.phone {
                title = "" //formatPhoneNumber("+\(phone)")
            } else {
                title = strings.User_DeletedAccount
            }
        case let .legacyGroup(group):
            title = group.title
        case let .channel(channel):
            title = channel.title
        case .secretChat:
            title = ""
        }
        return self.withAyuGramBadge(title)
    }
}

public extension EnginePeer.IndexName {
    func isLessThan(other: EnginePeer.IndexName, ordering: PresentationPersonNameOrder) -> ComparisonResult {
        switch self {
        case let .title(lhsTitle, _):
            let rhsString: String
            switch other {
            case let .title(title, _):
                rhsString = title
            case let .personName(first, last, _, _):
                switch ordering {
                case .firstLast:
                    if first.isEmpty {
                        rhsString = last
                    } else {
                        rhsString = first + last
                    }
                case .lastFirst:
                    if last.isEmpty {
                        rhsString = first
                    } else {
                        rhsString = last + first
                    }
                }
            }
            return lhsTitle.caseInsensitiveCompare(rhsString)
        case let .personName(lhsFirst, lhsLast, _, _):
            let lhsString: String
            switch ordering {
            case .firstLast:
                if lhsFirst.isEmpty {
                    lhsString = lhsLast
                } else {
                    lhsString = lhsFirst + lhsLast
                }
            case .lastFirst:
                if lhsLast.isEmpty {
                    lhsString = lhsFirst
                } else {
                    lhsString = lhsLast + lhsFirst
                }
            }
            let rhsString: String
            switch other {
            case let .title(title, _):
                rhsString = title
            case let .personName(first, last, _, _):
                switch ordering {
                case .firstLast:
                    if first.isEmpty {
                        rhsString = last
                    } else {
                        rhsString = first + last
                    }
                case .lastFirst:
                    if last.isEmpty {
                        rhsString = first
                    } else {
                        rhsString = last + first
                    }
                }
            }
            return lhsString.caseInsensitiveCompare(rhsString)
        }
    }
}

import Foundation

enum PSShortcutConflictPolicy {
    static func owners<Action: Equatable>(
        of binding: HotKeyBinding, excluding action: Action, candidates: [Action],
        lookup: (Action) -> HotKeyBinding?, holdsModifier: (Action, HotKeyBinding) -> Bool
    ) -> [Action] {
        candidates.filter { candidate in
            guard candidate != action, let other = lookup(candidate) else { return false }
            return binding.conflicts(with: other, holdsModifier: holdsModifier(candidate, other))
        }
    }
}

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let snapLeftThird = Self(
        "snapLeftThird",
        default: .init(.one, modifiers: [.control, .option])
    )

    static let snapCenterThird = Self(
        "snapCenterThird",
        default: .init(.two, modifiers: [.control, .option])
    )

    static let snapRightThird = Self(
        "snapRightThird",
        default: .init(.three, modifiers: [.control, .option])
    )
}
import UIKit

private let WFCardCornerRadius: CGFloat = 14
private let WFCardPadding: CGFloat = 14
private let WFPluginCardButtonWidth: CGFloat = 108

struct WFCardReferenceItem {
    let title: String
    let detail: String?
}

func WFMakeSection(title: String, footer: String? = nil, contents: [UIView]) -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 8

    let titleLabel = WFMakeTextLabel(title, font: .preferredFont(forTextStyle: .headline))
    stack.addArrangedSubview(titleLabel)

    contents.forEach { stack.addArrangedSubview($0) }

    if let footer, !footer.isEmpty {
        stack.addArrangedSubview(WFMakeFootnoteLabel(footer))
    }

    return stack
}

func WFMakeCard(_ arrangedSubviews: [UIView], spacing: CGFloat = 12) -> UIView {
    let stack = UIStackView(arrangedSubviews: arrangedSubviews)
    stack.axis = .vertical
    stack.spacing = spacing
    stack.translatesAutoresizingMaskIntoConstraints = false

    let container = UIView()
    container.backgroundColor = .secondarySystemGroupedBackground
    container.layer.cornerRadius = WFCardCornerRadius
    container.layer.cornerCurve = .continuous
    container.layer.borderWidth = 1 / UIScreen.main.scale
    container.layer.borderColor = UIColor.separator.withAlphaComponent(0.08).cgColor
    container.addSubview(stack)

    NSLayoutConstraint.activate([
        stack.topAnchor.constraint(equalTo: container.topAnchor, constant: WFCardPadding),
        stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: WFCardPadding),
        stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -WFCardPadding),
        stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -WFCardPadding),
    ])

    return container
}

func WFMakeCompactInfoRow(text: String, symbolName: String? = nil, tintColor: UIColor = .secondaryLabel) -> UIView {
    var arrangedSubviews: [UIView] = []
    if let symbolName {
        let imageView = UIImageView(image: UIImage(systemName: symbolName))
        imageView.tintColor = tintColor
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        arrangedSubviews.append(imageView)
    }

    let label = WFMakeFootnoteLabel(text, color: tintColor)
    label.numberOfLines = 0
    arrangedSubviews.append(label)

    let stack = UIStackView(arrangedSubviews: arrangedSubviews)
    stack.axis = .horizontal
    stack.alignment = .top
    stack.spacing = 8
    return stack
}

func WFMakeInfoCard(text: String) -> UIView {
    WFMakeCard([WFMakeReadableBodyLabel(text)])
}

func WFMakeActionRowCard(_ buttons: [UIButton]) -> UIView {
    let stack = UIStackView(arrangedSubviews: buttons)
    stack.axis = .horizontal
    stack.alignment = .fill
    stack.distribution = .fillEqually
    stack.spacing = 10

    buttons.forEach { button in
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.82
    }

    return WFMakeCard([stack], spacing: 0)
}

func WFMakeFeatureSummaryCard(
    title: String,
    detail: String,
    symbolName: String,
    tintColor: UIColor = .systemBlue
) -> UIView {
    var arrangedSubviews: [UIView] = [
        makeCardHeader(title: title, symbolName: symbolName, tintColor: tintColor),
    ]

    let segments = WFReadableSegments(from: detail)
    if segments.count <= 1 {
        arrangedSubviews.append(WFMakeReadableBodyLabel(detail))
    } else {
        arrangedSubviews.append(contentsOf: segments.map { makeReadableParagraphRow($0, tintColor: tintColor) })
    }

    return WFMakeCard(arrangedSubviews, spacing: 12)
}

func WFMakeBulletListCard(
    title: String,
    items: [String],
    symbolName: String,
    tintColor: UIColor = .systemOrange
) -> UIView {
    var arrangedSubviews: [UIView] = [
        makeCardHeader(title: title, symbolName: symbolName, tintColor: tintColor),
    ]
    arrangedSubviews.append(contentsOf: items.enumerated().map { index, item in
        makeIndexedBulletRow(item, index: index + 1, tintColor: tintColor)
    })
    return WFMakeCard(arrangedSubviews, spacing: 10)
}

func WFMakeReferenceListCard(
    title: String,
    items: [WFCardReferenceItem],
    symbolName: String,
    tintColor: UIColor = .systemBlue
) -> UIView {
    var arrangedSubviews: [UIView] = [
        makeCardHeader(title: title, symbolName: symbolName, tintColor: tintColor),
    ]
    arrangedSubviews.append(contentsOf: items.map(makeReferenceRow))
    return WFMakeCard(arrangedSubviews, spacing: 10)
}

func WFMakeTextLabel(_ text: String, font: UIFont, color: UIColor = .label, lines: Int = 0) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = font
    label.textColor = color
    label.numberOfLines = lines
    label.adjustsFontForContentSizeCategory = true
    return label
}

func WFMakeSecondaryLabel(_ text: String) -> UILabel {
    WFMakeTextLabel(text, font: .preferredFont(forTextStyle: .subheadline), color: .secondaryLabel)
}

func WFMakeReadableBodyLabel(_ text: String, color: UIColor = .secondaryLabel) -> UILabel {
    let label = UILabel()
    label.numberOfLines = 0
    label.adjustsFontForContentSizeCategory = true
    label.textColor = color

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 4
    paragraphStyle.paragraphSpacing = 8
    paragraphStyle.lineBreakMode = .byWordWrapping
    paragraphStyle.alignment = .natural

    label.attributedText = NSAttributedString(
        string: text,
        attributes: [
            .font: UIFont.preferredFont(forTextStyle: .subheadline),
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ]
    )
    return label
}

func WFMakeFootnoteLabel(_ text: String, color: UIColor = .secondaryLabel) -> UILabel {
    WFMakeTextLabel(text, font: .preferredFont(forTextStyle: .footnote), color: color)
}

func WFMakeActionButton(
    title: String,
    systemImage: String? = nil,
    isPrimary: Bool = true,
    isLoading: Bool = false,
    isEnabled: Bool = true,
    buttonSize: UIButton.Configuration.Size = .large,
    tintColor: UIColor? = nil,
    action: @escaping () -> Void
) -> UIButton {
    var configuration = isPrimary ? UIButton.Configuration.filled() : UIButton.Configuration.gray()
    configuration.title = title
    configuration.cornerStyle = .medium
    configuration.buttonSize = buttonSize
    configuration.imagePadding = 8
    configuration.showsActivityIndicator = isLoading
    if let systemImage {
        configuration.image = UIImage(systemName: systemImage)
    }

    let button = UIButton(configuration: configuration, primaryAction: UIAction { _ in
        action()
    })
    button.isEnabled = isEnabled && !isLoading
    button.titleLabel?.adjustsFontSizeToFitWidth = true
    button.titleLabel?.minimumScaleFactor = 0.82
    if let tintColor {
        button.tintColor = tintColor
    }
    return button
}

func WFMakeStatusBadge(state: WatchCompatibilityState, title: String? = nil) -> UIView {
    let imageView = UIImageView(image: UIImage(systemName: state.symbolName))
    imageView.tintColor = state.tintColor
    imageView.setContentHuggingPriority(.required, for: .horizontal)

    let label = WFMakeFootnoteLabel(title ?? state.title, color: state.tintColor)
    label.font = .preferredFont(forTextStyle: .caption1).withSize(12)
    label.numberOfLines = 1
    label.lineBreakMode = .byTruncatingTail

    let stack = UIStackView(arrangedSubviews: [imageView, label])
    stack.axis = .horizontal
    stack.alignment = .center
    stack.spacing = 6
    stack.translatesAutoresizingMaskIntoConstraints = false

    let container = UIView()
    container.backgroundColor = state.tintColor.withAlphaComponent(0.14)
    container.layer.cornerRadius = 999
    container.addSubview(stack)
    container.setContentHuggingPriority(.required, for: .horizontal)
    container.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

    NSLayoutConstraint.activate([
        stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 5),
        stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 9),
        stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -9),
        stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -5),
    ])

    return container
}

func WFMakeValueRow(title: String, value: String) -> UIView {
    let titleLabel = WFMakeSecondaryLabel(title)
    titleLabel.numberOfLines = 1
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

    let valueLabel = WFMakeTextLabel(value, font: .preferredFont(forTextStyle: .body), lines: 0)
    valueLabel.textAlignment = .right
    valueLabel.lineBreakMode = .byWordWrapping
    valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    let spacer = UIView()
    spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    let stack = UIStackView(arrangedSubviews: [titleLabel, spacer, valueLabel])
    stack.axis = .horizontal
    stack.alignment = .top
    stack.spacing = 8
    return stack
}

func WFMakeIconTile(image: UIImage?, symbolName: String, tintColor: UIColor) -> UIView {
    let resolvedImage = image ?? UIImage(systemName: symbolName)
    let imageView = UIImageView(image: resolvedImage)
    imageView.tintColor = image == nil ? tintColor : nil
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false

    let container = UIView()
    container.backgroundColor = image == nil ? tintColor.withAlphaComponent(0.14) : .secondarySystemGroupedBackground
    container.layer.cornerRadius = 10
    container.layer.cornerCurve = .continuous
    container.clipsToBounds = true
    container.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(imageView)

    NSLayoutConstraint.activate([
        container.widthAnchor.constraint(equalToConstant: 36),
        container.heightAnchor.constraint(equalToConstant: 36),
        imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
        imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
        imageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
        imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
    ])

    return container
}

private func makeCardHeader(title: String, symbolName: String, tintColor: UIColor) -> UIView {
    let iconView = WFMakeIconTile(image: nil, symbolName: symbolName, tintColor: tintColor)
    let titleLabel = WFMakeTextLabel(title, font: .preferredFont(forTextStyle: .headline))
    let stack = UIStackView(arrangedSubviews: [iconView, titleLabel])
    stack.axis = .horizontal
    stack.alignment = .center
    stack.spacing = 12
    return stack
}

private func makeIndexedBulletRow(_ text: String, index: Int, tintColor: UIColor) -> UIView {
    let badgeLabel = WFMakeTextLabel(
        "\(index)",
        font: .preferredFont(forTextStyle: .caption1).withSize(12),
        color: tintColor,
        lines: 1
    )
    badgeLabel.textAlignment = .center

    let badgeContainer = UIView()
    badgeContainer.backgroundColor = tintColor.withAlphaComponent(0.14)
    badgeContainer.layer.cornerRadius = 11
    badgeContainer.layer.cornerCurve = .continuous
    badgeContainer.translatesAutoresizingMaskIntoConstraints = false
    badgeContainer.addSubview(badgeLabel)
    badgeLabel.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
        badgeContainer.widthAnchor.constraint(equalToConstant: 22),
        badgeContainer.heightAnchor.constraint(equalToConstant: 22),
        badgeLabel.centerXAnchor.constraint(equalTo: badgeContainer.centerXAnchor),
        badgeLabel.centerYAnchor.constraint(equalTo: badgeContainer.centerYAnchor),
    ])

    badgeContainer.setContentHuggingPriority(.required, for: .horizontal)
    badgeContainer.setContentCompressionResistancePriority(.required, for: .horizontal)

    let label = WFMakeReadableBodyLabel(text)
    let stack = UIStackView(arrangedSubviews: [badgeContainer, label])
    stack.axis = .horizontal
    stack.alignment = .top
    stack.spacing = 10
    return stack
}

private func makeReadableParagraphRow(_ text: String, tintColor: UIColor) -> UIView {
    let accentBar = UIView()
    accentBar.backgroundColor = tintColor.withAlphaComponent(0.35)
    accentBar.layer.cornerRadius = 1.5
    accentBar.translatesAutoresizingMaskIntoConstraints = false
    accentBar.setContentHuggingPriority(.required, for: .horizontal)
    accentBar.setContentCompressionResistancePriority(.required, for: .horizontal)

    NSLayoutConstraint.activate([
        accentBar.widthAnchor.constraint(equalToConstant: 3),
    ])

    let label = WFMakeReadableBodyLabel(text)
    let stack = UIStackView(arrangedSubviews: [accentBar, label])
    stack.axis = .horizontal
    stack.alignment = .top
    stack.spacing = 10
    return stack
}

private func WFReadableSegments(from text: String) -> [String] {
    let normalizedLines = text
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    if normalizedLines.count > 1 {
        return normalizedLines
    }

    var sentences: [String] = []
    var current = ""
    var insideInlineCode = false
    let characters = Array(text)
    for (index, character) in characters.enumerated() {
        current.append(character)

        if character == "`" {
            insideInlineCode.toggle()
            continue
        }

        if insideInlineCode {
            continue
        }

        let shouldBreak: Bool
        switch character {
        case "。", "！", "？", "；":
            shouldBreak = true
        case ".", "!", "?", ";":
            let nextCharacter = index + 1 < characters.count ? characters[index + 1] : nil
            shouldBreak = nextCharacter.map(\.isWhitespace) ?? true
        default:
            shouldBreak = false
        }

        if shouldBreak {
            let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                sentences.append(trimmed)
            }
            current.removeAll(keepingCapacity: true)
        }
    }

    let trailing = current.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trailing.isEmpty {
        sentences.append(trailing)
    }

    if sentences.count <= 1 {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? [] : [trimmed]
    }

    return sentences
}

private func makeReferenceRow(_ item: WFCardReferenceItem) -> UIView {
    let titleLabel = WFMakeTextLabel(item.title, font: .preferredFont(forTextStyle: .subheadline))
    var arrangedSubviews: [UIView] = [titleLabel]
    if let detail = item.detail, !detail.isEmpty {
        arrangedSubviews.append(WFMakeFootnoteLabel(detail))
    }

    let stack = UIStackView(arrangedSubviews: arrangedSubviews)
    stack.axis = .vertical
    stack.spacing = 2
    return stack
}

func WFMakeCompatibilityCard(report: WatchCompatibilityReport) -> UIView {
    let titleLabel = WFMakeTextLabel(report.watchName, font: .preferredFont(forTextStyle: .headline))
    let sourceLabel = WFMakeFootnoteLabel(report.sourceLabel)
    let titleStack = UIStackView(arrangedSubviews: [titleLabel, sourceLabel])
    titleStack.axis = .vertical
    titleStack.spacing = 4

    let headerStack = UIStackView(arrangedSubviews: [titleStack, UIView(), WFMakeStatusBadge(state: report.state)])
    headerStack.axis = .horizontal
    headerStack.alignment = .top

    var arrangedSubviews: [UIView] = [headerStack, WFMakeSecondaryLabel(report.detailText)]
    if report.inferred {
        arrangedSubviews.append(WFMakeFootnoteLabel(L("compatibility.flag.inferred"), color: .systemOrange))
    }
    if let watchOSVersion = report.watchOSVersion {
        arrangedSubviews.append(WFMakeValueRow(title: L("compatibility.field.watchOS"), value: watchOSVersion))
    }
    if let productType = report.productType {
        arrangedSubviews.append(WFMakeValueRow(title: L("compatibility.field.product"), value: productType))
    }
    if let chipID = report.chipID {
        arrangedSubviews.append(WFMakeValueRow(title: L("compatibility.field.chipID"), value: chipID))
    }
    if let targetMax = report.deviceMaxCompatibilityVersion {
        arrangedSubviews.append(WFMakeValueRow(title: L("compatibility.field.target"), value: "\(targetMax)"))
    }
    if let systemMin = report.systemMinCompatibilityVersion {
        arrangedSubviews.append(WFMakeValueRow(title: L("compatibility.field.systemMin"), value: "\(systemMin)"))
    }
    if let systemMax = report.systemMaxCompatibilityVersion {
        arrangedSubviews.append(WFMakeValueRow(title: L("compatibility.field.systemMax"), value: "\(systemMax)"))
    }

    return WFMakeCard(arrangedSubviews)
}

func WFMakeUpdateCard(status: LatestUpdateStatus) -> UIView {
    let nameLabel = WFMakeTextLabel(
        status.updateName ?? L("update.none.title"),
        font: .preferredFont(forTextStyle: .headline)
    )
    let headerStack = UIStackView(arrangedSubviews: [nameLabel, UIView(), WFMakeStatusBadge(state: status.state, title: status.title)])
    headerStack.axis = .horizontal
    headerStack.alignment = .top

    var arrangedSubviews: [UIView] = [headerStack, WFMakeSecondaryLabel(status.detailText)]
    if let updateVersion = status.updateVersion {
        arrangedSubviews.append(WFMakeValueRow(title: L("update.field.version"), value: updateVersion))
    }
    if let buildVersion = status.buildVersion {
        arrangedSubviews.append(WFMakeValueRow(title: L("update.field.build"), value: buildVersion))
    }
    if let osName = status.osName {
        arrangedSubviews.append(WFMakeValueRow(title: L("update.field.osName"), value: osName))
    }
    if let publisher = status.publisher {
        arrangedSubviews.append(WFMakeValueRow(title: L("update.field.publisher"), value: publisher))
    }
    if let downloadSize = status.downloadSize {
        let formatted = ByteCountFormatter.string(fromByteCount: downloadSize, countStyle: .file)
        arrangedSubviews.append(WFMakeValueRow(title: L("update.field.downloadSize"), value: formatted))
    }
    if let preparationSize = status.preparationSize {
        let formatted = ByteCountFormatter.string(fromByteCount: preparationSize, countStyle: .file)
        arrangedSubviews.append(WFMakeValueRow(title: L("update.field.preparationSize"), value: formatted))
    }
    if let installationSize = status.installationSize {
        let formatted = ByteCountFormatter.string(fromByteCount: installationSize, countStyle: .file)
        arrangedSubviews.append(WFMakeValueRow(title: L("update.field.installationSize"), value: formatted))
    }
    if let totalRequiredFreeSpace = status.totalRequiredFreeSpace {
        let formatted = ByteCountFormatter.string(fromByteCount: totalRequiredFreeSpace, countStyle: .file)
        arrangedSubviews.append(WFMakeValueRow(title: L("update.field.totalRequiredFreeSpace"), value: formatted))
    }
    if let marketingVersion = status.marketingVersion {
        arrangedSubviews.append(WFMakeValueRow(title: L("update.field.marketingVersion"), value: marketingVersion))
    }
    if let productSystemName = status.productSystemName {
        arrangedSubviews.append(WFMakeValueRow(title: L("update.field.productSystemName"), value: productSystemName))
    }
    if let documentationID = status.documentationID {
        arrangedSubviews.append(WFMakeValueRow(title: L("update.field.documentationID"), value: documentationID))
    }
    if let manifestLength = status.manifestLength {
        arrangedSubviews.append(WFMakeValueRow(title: L("update.field.manifestLength"), value: "\(manifestLength)"))
    }
    if let terms = status.terms {
        arrangedSubviews.append(WFMakeValueRow(title: L("update.field.terms"), value: terms ? L("common.yes") : L("common.no")))
    }
    if let installTonightScheduled = status.installTonightScheduled {
        arrangedSubviews.append(WFMakeValueRow(title: L("update.field.installTonightScheduled"), value: installTonightScheduled ? L("common.yes") : L("common.no")))
    }
    if let displayTermsRequested = status.displayTermsRequested {
        arrangedSubviews.append(WFMakeValueRow(title: L("update.field.displayTermsRequested"), value: displayTermsRequested ? L("common.yes") : L("common.no")))
    }

    return WFMakeCard(arrangedSubviews)
}

func WFMakePluginCard(
    plugin: PluginState,
    isBusy: Bool,
    actionTitle: String? = nil,
    systemImage: String? = nil,
    isPrimary: Bool? = nil,
    tintColor: UIColor? = nil,
    isActionEnabled: Bool? = nil,
    configurationTitle: String? = nil,
    configurationSystemImage: String? = nil,
    isConfigurationEnabled: Bool = true,
    onConfiguration: (() -> Void)? = nil,
    onAction: @escaping () -> Void
) -> UIView {
    let iconView = WFMakeIconTile(
        image: WFPluginBridge.pluginIcon(forScopeIdentifier: plugin.metadata.scopeIdentifier),
        symbolName: plugin.metadata.symbolName,
        tintColor: .systemBlue
    )
    let titleLabel = WFMakeTextLabel(plugin.title, font: .preferredFont(forTextStyle: .headline))
    let detailLabel = WFMakeSecondaryLabel(plugin.detail)
    titleLabel.numberOfLines = 0
    detailLabel.numberOfLines = 0

    let textStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
    textStack.axis = .vertical
    textStack.spacing = 4
    textStack.alignment = .fill
    textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
    iconView.setContentHuggingPriority(.required, for: .horizontal)

    let actionButton = WFMakeActionButton(
        title: actionTitle ?? (plugin.available ? L("common.delete") : L("common.install")),
        systemImage: systemImage ?? (plugin.available ? "trash" : "square.and.arrow.down"),
        isPrimary: isPrimary ?? !plugin.available,
        isLoading: isBusy,
        isEnabled: isActionEnabled ?? (plugin.available || plugin.canInstall),
        buttonSize: .medium,
        tintColor: tintColor ?? (plugin.available ? .systemRed : nil)
    ) {
        onAction()
    }
    actionButton.translatesAutoresizingMaskIntoConstraints = false
    actionButton.widthAnchor.constraint(equalToConstant: WFPluginCardButtonWidth).isActive = true
    var buttonViews: [UIView] = []
    if let onConfiguration {
        let configurationButton = WFMakeActionButton(
            title: configurationTitle ?? L("features.plugins.configure"),
            systemImage: configurationSystemImage ?? "slider.horizontal.3",
            isPrimary: false,
            isLoading: false,
            isEnabled: isConfigurationEnabled && !isBusy,
            buttonSize: .medium
        ) {
            onConfiguration()
        }
        configurationButton.translatesAutoresizingMaskIntoConstraints = false
        configurationButton.widthAnchor.constraint(equalToConstant: WFPluginCardButtonWidth).isActive = true
        buttonViews.append(configurationButton)
    }
    buttonViews.append(actionButton)

    let buttonStack = UIStackView(arrangedSubviews: buttonViews)
    buttonStack.axis = .vertical
    buttonStack.alignment = .fill
    buttonStack.spacing = 8
    buttonStack.setContentHuggingPriority(.required, for: .horizontal)
    buttonStack.setContentCompressionResistancePriority(.required, for: .horizontal)

    let rowStack = UIStackView(arrangedSubviews: [iconView, textStack, buttonStack])
    rowStack.axis = .horizontal
    rowStack.alignment = .center
    rowStack.spacing = 12

    var arrangedSubviews: [UIView] = [rowStack]
    if !plugin.available && plugin.canInstall {
        arrangedSubviews.append(WFMakeFootnoteLabel(L("features.plugins.unavailable"), color: .systemOrange))
    }
    if let validationMessage = plugin.validationMessage {
        let validationColor: UIColor
        switch plugin.validation.state {
        case .compatible:
            validationColor = .secondaryLabel
        case .incompatible:
            validationColor = .systemRed
        case .indeterminate:
            validationColor = .systemRed
        }
        arrangedSubviews.append(WFMakeFootnoteLabel(validationMessage, color: validationColor))
    }
    if let updateMessage = plugin.updateMessage {
        arrangedSubviews.append(WFMakeFootnoteLabel(updateMessage, color: .systemOrange))
    }

    return WFMakeCard(arrangedSubviews)
}

func WFMakePluginHeaderCard(plugin: PluginState) -> UIView {
    let iconView = WFMakeIconTile(
        image: WFPluginBridge.pluginIcon(forScopeIdentifier: plugin.metadata.scopeIdentifier),
        symbolName: plugin.metadata.symbolName,
        tintColor: .systemBlue
    )
    let titleLabel = WFMakeTextLabel(plugin.title, font: .preferredFont(forTextStyle: .headline))
    titleLabel.numberOfLines = 0
    titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    iconView.setContentHuggingPriority(.required, for: .horizontal)

    let status = WFMakeStatusBadge(
        state: plugin.available ? .compatible : .unavailable,
        title: plugin.available ? L("plugin.configuration.status.installed") : L("plugin.configuration.status.notInstalled")
    )
    status.setContentHuggingPriority(.required, for: .horizontal)
    status.setContentCompressionResistancePriority(.required, for: .horizontal)

    let spacer = UIView()
    spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    let rowStack = UIStackView(arrangedSubviews: [iconView, titleLabel, spacer, status])
    rowStack.axis = .horizontal
    rowStack.alignment = .center
    rowStack.spacing = 12

    let detailLabel = WFMakeSecondaryLabel(plugin.detail)
    detailLabel.numberOfLines = 0
    detailLabel.font = .preferredFont(forTextStyle: .subheadline)

    var arrangedSubviews: [UIView] = [rowStack, detailLabel]
    if let validationMessage = plugin.validationMessage {
        arrangedSubviews.append(WFMakeFootnoteLabel(validationMessage, color: plugin.validation.state == .compatible ? .secondaryLabel : .systemRed))
    }
    if let updateMessage = plugin.updateMessage {
        arrangedSubviews.append(WFMakeFootnoteLabel(updateMessage, color: .systemOrange))
    }

    return WFMakeCard(arrangedSubviews)
}

func WFMakeToggleCard(
    title: String,
    detail: String,
    isOn: Bool,
    isEnabled: Bool = true,
    onChange: @escaping (Bool) -> Void
) -> UIView {
    let titleLabel = WFMakeTextLabel(title, font: .preferredFont(forTextStyle: .headline))
    let detailLabel = WFMakeSecondaryLabel(detail)
    let textStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
    textStack.axis = .vertical
    textStack.spacing = 4

    let toggle = UISwitch()
    toggle.isOn = isOn
    toggle.isEnabled = isEnabled
    toggle.addAction(UIAction { _ in
        onChange(toggle.isOn)
    }, for: .valueChanged)
    toggle.setContentHuggingPriority(.required, for: .horizontal)

    let rowStack = UIStackView(arrangedSubviews: [textStack, UIView(), toggle])
    rowStack.axis = .horizontal
    rowStack.alignment = .center
    rowStack.spacing = 12

    return WFMakeCard([rowStack])
}

func WFMakeCodeCard(text: String) -> UIView {
    let label = WFMakeTextLabel(
        text,
        font: .monospacedSystemFont(ofSize: 12, weight: .regular),
        color: .label
    )
    return WFMakeCard([label])
}

func WFMakeStepperCard(
    title: String,
    value: Int,
    range: ClosedRange<Int>,
    onChange: @escaping (Int) -> Void
) -> UIView {
    let titleLabel = WFMakeTextLabel(title, font: .preferredFont(forTextStyle: .headline))
    let valueLabel = WFMakeTextLabel("\(value)", font: .preferredFont(forTextStyle: .headline))
    valueLabel.textAlignment = .right
    valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

    let headerStack = UIStackView(arrangedSubviews: [titleLabel, UIView(), valueLabel])
    headerStack.axis = .horizontal
    headerStack.alignment = .firstBaseline

    let stepper = UIStepper()
    stepper.minimumValue = Double(range.lowerBound)
    stepper.maximumValue = Double(range.upperBound)
    stepper.stepValue = 1
    stepper.value = Double(value)
    stepper.addAction(UIAction { _ in
        onChange(Int(stepper.value))
    }, for: .valueChanged)

    let controls = UIStackView(arrangedSubviews: [stepper, UIView()])
    controls.axis = .horizontal
    controls.alignment = .center

    return WFMakeCard([headerStack, controls])
}

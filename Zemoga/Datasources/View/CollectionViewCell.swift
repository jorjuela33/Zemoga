//
//  CollectionViewCell.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import UIKit

class Action {
    typealias ActionCallback = (CollectionViewCell) -> Void

    let callback: ActionCallback?
    var isDestructive: Bool
    let title: String

    // MARK: Initializers

    init(title: String, isDestructive: Bool = false, callback: ActionCallback? = nil) {
        self.callback = callback
        self.isDestructive = isDestructive
        self.title = title
    }
}

class ActionsView: UIView {
    private var editActionConstraints: [NSLayoutConstraint] = []
    private var actionButtons: [UIButton] = [] {
        didSet {
            removeConstraints(editActionConstraints)
            editActionConstraints.removeAll()

            actionButtons.forEach({ self.addSubview($0) })
            oldValue.forEach({ $0.removeFromSuperview() })

            for (index, actionButton) in actionButtons.enumerated() {
                editActionConstraints.append(actionButton.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1))
                editActionConstraints.append(actionButton.topAnchor.constraint(equalTo: topAnchor))
                if index == 0 {
                    editActionConstraints.append(actionButton.rightAnchor.constraint(equalTo: rightAnchor))
                } else if index > 0 {
                    editActionConstraints.append(actionButton.rightAnchor.constraint(equalTo: actionButtons[index - 1].rightAnchor))
                }

                if index == actionButtons.count - 1 {
                     editActionConstraints.append(actionButton.leftAnchor.constraint(equalTo: leftAnchor))
                }

                actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
            }

            addConstraints(editActionConstraints)
        }
    }

    weak var cell: CollectionViewCell?

    lazy var maskLayer: CALayer = {
        let maskLayer = CALayer()
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.delegate = self
        return maskLayer
    }()

    var visibleWidth: CGFloat = 0 {
        didSet {
            let visibleWidth = min(self.visibleWidth, bounds.width)
            maskLayer.frame = CGRect(x: bounds.width - visibleWidth, y: 0, width: visibleWidth, height: bounds.height)
        }
    }

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    // MARK: Actions

    @IBAction private func didTouchUpInsideMoreActions(_ sender: UIButton) {
        guard let cell = cell else { return }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancelar", style: .destructive, handler: nil)
        alertController.addAction(cancelAction)

        for (index, editingAction) in cell.editActions.enumerated() where index > 0 {
            let alertAction = UIAlertAction(title: editingAction.title, style: .default) { _ in editingAction.callback?(cell) }
            alertController.addAction(alertAction)
        }

        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }

    @IBAction private func touchUpInside(_ sender: UIButton) {
        guard
            /// index of the touched button
            let index = actionButtons.lastIndex(where: { $0 === sender }),

            /// associated cell
            let cell = cell else { return }

        isUserInteractionEnabled = false
        cell.editActions[index].callback?(cell)
    }

    // MARK: Instance methods

    func prepareActionButtons() {
        guard let editingActions = cell?.editActions else { return }

        actionButtons.removeAll()

        for (index, editingAction) in editingActions.enumerated() {
            let button = UIButton(type: .custom)
            button.addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
            button.backgroundColor = editingAction.isDestructive ? .red : .white
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 9, bottom: 0, right: 9)
            button.setTitle(editingAction.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
            button.titleLabel?.numberOfLines = 0
            button.translatesAutoresizingMaskIntoConstraints = false
            actionButtons.append(button)
            if index == 0 && editingActions.count > 2 {
                break
            }
        }

        if editingActions.count > 2 {
            let moreActionsButton = UIButton(type: .custom)
            moreActionsButton.addTarget(self, action: #selector(didTouchUpInsideMoreActions(_:)), for: .touchUpInside)
            moreActionsButton.backgroundColor = .gray
            moreActionsButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 9, bottom: 0, right: 9)
            moreActionsButton.setTitle("More", for: .normal)
            moreActionsButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
            moreActionsButton.titleLabel?.numberOfLines = 0
            moreActionsButton.translatesAutoresizingMaskIntoConstraints = false
            actionButtons.append(moreActionsButton)
        }
    }

    // MARK: Private methods

    private func commonInit() {
        layer.mask = maskLayer
        isUserInteractionEnabled = false
    }
}

class CollectionViewCell: UICollectionViewCell {
    private var contentLeftConstraint: NSLayoutConstraint!
    private var contentWidthConstraint: NSLayoutConstraint!
    private var editActionConstraints: [NSLayoutConstraint] = []
    private lazy var containerView: UIView = {
        let containerView = UIView(frame: .zero)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()

    lazy var actionsView: ActionsView = {
        let actionsView = ActionsView(frame: .zero)
        actionsView.cell = self
        actionsView.translatesAutoresizingMaskIntoConstraints = false
        return actionsView
    }()

    var isUserInteractionEnabledForEditing: Bool = false {
        didSet {
            actionsView.isUserInteractionEnabled = isUserInteractionEnabledForEditing
        }
    }

    var minimumSwipeTrackingPosition: CGFloat {
        return actionsView.frame.minX - super.contentView.frame.width
    }

    var swipeTrackingPosition: CGFloat {
        get {
            return containerView.frame.origin.x
        }

        set {
            if isEditing {
                contentLeftConstraint.constant = newValue + 15
            } else {
                containerView.frame.origin.x = newValue
            }

             actionsView.visibleWidth = max(0, -newValue)
        }
    }

    /// an array of Action instances that should be displayed when this cell has been swiped for editing.
    var editActions: [Action] = []

    /// whether or not the cell is editing
    var isEditing = false {
        didSet {
            containerView.isUserInteractionEnabled = !isEditing
        }
    }

    override var contentView: UIView {
        return containerView
    }

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    // MARK: Instance methods

    func closeActionPane(animated: Bool, completionCallback: @escaping(Bool) -> Void) {
        let duration = animated ? 0.25 : 0
        UIView.animate(
            withDuration: duration,
            animations: {
            self.swipeTrackingPosition = 0
            },
            completion: { finished in
            if !self.isEditing {
                self.addConstraint(self.contentLeftConstraint)
            }
            completionCallback(true)
            })
    }

    func closeForDelete() {
        actionsView.maskLayer.frame.size.height = 0
        containerView.frame.origin.x -= containerView.frame.width
    }

    func hideEditActions() {
        removeConstraints(editActionConstraints)
        actionsView.removeFromSuperview()
    }

    func openActionPane(animated: Bool, completionCallback: @escaping(Bool) -> Void) {
        showEditActions()
        let duration = animated ? 0.25 : 0
        UIView.animate(
            withDuration: duration,
            animations: {
            self.swipeTrackingPosition = self.minimumSwipeTrackingPosition
            self.layoutIfNeeded()
            },
            completion: completionCallback)
    }

    func preferredLayoutSizeFittingSize(_ size: CGSize) -> CGSize {
        frame.size = systemLayoutSizeFitting(size, withHorizontalFittingPriority: .defaultHigh, verticalFittingPriority: .fittingSizeLevel)
        return frame.size
    }

    func showEditActions() {
        let contentView = super.contentView
        contentView.addSubview(actionsView)
        prepareEditActionsConstraintsIfNeeded()
        addConstraints(editActionConstraints)
        actionsView.prepareActionButtons()

        if !isEditing {
            removeConstraint(contentLeftConstraint)
        }

        actionsView.layoutIfNeeded()
        // Prevent the weird animated mask layer
        actionsView.visibleWidth = 1
        actionsView.visibleWidth = 0
    }

    // MARK: Private methods

    private func commonInit() {
        let contentView = super.contentView
        contentView.addSubview(containerView)
        contentView.clipsToBounds = true
        contentLeftConstraint = containerView.leftAnchor.constraint(equalTo: leftAnchor)
        contentWidthConstraint = containerView.widthAnchor.constraint(equalTo: contentView.widthAnchor)
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentLeftConstraint,
            contentWidthConstraint
        ])
    }

    private func prepareEditActionsConstraintsIfNeeded() {
        guard editActionConstraints.isEmpty else { return }

        let contentView = super.contentView
        editActionConstraints.append(actionsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor))
        editActionConstraints.append(actionsView.rightAnchor.constraint(equalTo: contentView.rightAnchor))
        editActionConstraints.append(actionsView.topAnchor.constraint(equalTo: contentView.topAnchor))
    }
}

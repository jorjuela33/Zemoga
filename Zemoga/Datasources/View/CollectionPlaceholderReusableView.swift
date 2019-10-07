//
//  CollectionPlaceholderReusableView.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import UIKit

typealias PlaceHolderActionCallback = () -> Void

class PlaceHolderView: UIView {
    lazy var actionButton: UIButton = {
        let actionButton = UIButton(type: .system)
        actionButton.backgroundColor = .blue
        actionButton.layer.cornerRadius = 6
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        actionButton.titleLabel?.textAlignment = .center
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(actionButtonPressed(_:)), for: .touchUpInside)
        return actionButton
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: nil)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    lazy var messageLabel: UILabel = {
        let messageLabel = UILabel(frame: .zero)
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.textColor = .lightGray
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        return messageLabel
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: .zero)
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()

    var actionCallback: PlaceHolderActionCallback?

    // MARK: Initializers

    convenience init(
        frame: CGRect,
        title: String,
        message: String,
        image: UIImage?,
        actionTitle: String?,
        actionCallback: PlaceHolderActionCallback?
        ) {

        self.init(frame: frame)
        self.actionCallback = actionCallback
        self.messageLabel.text = message
        self.titleLabel.text = title

        addSubview(titleLabel)
        addSubview(messageLabel)

        if let image = image {
            self.imageView.image = image
            addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
                imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.4),
                titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 40)
            ])

            addConstraint(
                NSLayoutConstraint(
                    item: imageView,
                    attribute: .centerY,
                    relatedBy: .equal,
                    toItem: self,
                    attribute: .centerY,
                    multiplier: 0.75,
                    constant: 0
                )
            )
        } else {
            addConstraint(
                NSLayoutConstraint(
                    item: titleLabel,
                    attribute: .centerY,
                    relatedBy: .equal,
                    toItem: self,
                    attribute: .centerY,
                    multiplier: 0.75,
                    constant: 0
                )
            )
        }

        if let actionTitle = actionTitle {
            let heightAnchor = actionButton.heightAnchor.constraint(equalTo: actionButton.widthAnchor, multiplier: 15 / 61)
            let widthAnchor = actionButton.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.488)
            actionButton.setTitle(actionTitle, for: .normal)
            heightAnchor.priority = .defaultLow
            widthAnchor.priority = .defaultLow
            addSubview(actionButton)
            NSLayoutConstraint.activate([
                actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
                actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 45),
                actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 40),
                actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 183),
                heightAnchor,
                widthAnchor
            ])
        }

        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            messageLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.71),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    // MARK: Actions

    @IBAction private func actionButtonPressed(_ sender: UIButton) {
        actionCallback?()
    }
}

class CollectionPlaceholderReusableView: UICollectionReusableView {
    private var placeholderView: PlaceHolderView?

    private lazy var activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.color = .lightGray
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)
        activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        return activityIndicatorView
    }()

    // MARK: Instance methods

    /// hides the placeholder view.
    func hidePlaceholder(animated: Bool) {
        guard let placeholderView = placeholderView else { return }

        let duration = animated ? 0.25 : 0
        UIView.animate(withDuration: duration, animations: {
            placeholderView.alpha = 0
        }) { _ in
            placeholderView.removeFromSuperview()
            guard placeholderView === placeholderView else { return }

            self.placeholderView = nil
        }
    }

    /// shows a placeholder view for use in the collection view. This placeholder includes the loading indicator.
    func showActivityIndicator(_ show: Bool) {
        activityIndicatorView.isHidden = !show
        guard show else {
            activityIndicatorView.stopAnimating()
            return
        }

        activityIndicatorView.startAnimating()
    }

    /// shows a placeholder view for use in the collection view.
    func showPlaceholderWithTitle(
        _ title: String,
        message: String,
        image: UIImage?,
        actionTitle: String?,
        actionCallback: PlaceHolderActionCallback?
        ) -> Bool {

        let oldPlaceholderView = self.placeholderView

        guard oldPlaceholderView?.titleLabel.text != title || oldPlaceholderView?.messageLabel.text != message else {
            return false
        }

        showActivityIndicator(false)

        let placeholderView = PlaceHolderView(
            frame: frame,
            title: title,
            message: message,
            image: image,
            actionTitle: actionTitle,
            actionCallback: actionCallback
        )
        placeholderView.alpha = 0
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderView)
        placeholderView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        placeholderView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        self.placeholderView = placeholderView

        UIView.animate(
            withDuration: 0.25,
            animations: {
                placeholderView.alpha = 1
                oldPlaceholderView?.alpha = 0
            },
            completion: { _ in
                oldPlaceholderView?.removeFromSuperview()
            })

        return true
    }
}

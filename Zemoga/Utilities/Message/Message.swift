//
//  Message.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import UIKit

struct Message {
    let title: String?
    let message: String?
    let actions: [UIAlertAction]
    let preferedAction:  UIAlertAction?
    let preferedStyle: UIAlertController.Style

    // MARK: Initializers

    init(
        title: String? = nil,
        message: String? = nil,
        actions: [UIAlertAction] = [],
        preferedAction: UIAlertAction? = nil,
        preferedStyle: UIAlertController.Style = .alert
        ) {

        var messageActions = actions
        if messageActions.isEmpty {
            let cancelAction = UIAlertAction(title: "OK", style: .cancel)
            messageActions.append(cancelAction)
        }
        self.actions = messageActions
        self.message = message
        self.preferedAction = preferedAction
        self.preferedStyle = preferedStyle
        self.title = title
    }
}

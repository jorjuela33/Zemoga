//
//  LoadingIndicator.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/6/19.
//

import MBProgressHUD

class LoadingIndicator: MBProgressHUD {

    var loadingMessage: String? {
        get {
            return label.text
        }

        set {
            label.text = newValue
        }
    }

    // MARK: Class methods

    class func show(in view: UIView, loadingMessage: String = "Loading....") -> LoadingIndicator {
        let loadingIndicator = LoadingIndicator.showAdded(to: view, animated: false)
        loadingIndicator.removeFromSuperViewOnHide = false
        loadingIndicator.hide(animated: false)
        loadingIndicator.label.text = loadingMessage
        loadingIndicator.contentColor = .white
        loadingIndicator.bezelView.color = UIColor.black.withAlphaComponent(0.75)
        loadingIndicator.bezelView.style = .solidColor
        return loadingIndicator
    }
}

//
//  UIViewController.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import UIKit.UIViewController

protocol StoryboardIdentifiable: NSObjectProtocol {
    static var storyboardIdentifier: String { get }
}

extension UIViewController: NavigationConfigurable, StoryboardIdentifiable {

    var configuration: NavigationConfigurator {
        return NavigationConfigurator.default
    }

    var prefersLargeTitles: Bool {
        return false
    }

    var prefersNavigationBarHidden: Bool {
        return false
    }

    static var storyboardIdentifier: String {
        return String(describing: self)
    }
}

extension UIViewController {

    // MARK: Instance methods

    func showMessage(_ message: String, title: String = "Attention!") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
}

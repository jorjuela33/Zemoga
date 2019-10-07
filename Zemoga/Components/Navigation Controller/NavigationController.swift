//
//  NavigationController.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import UIKit

@objc
protocol NavigationConfigurable {
    var configuration: NavigationConfigurator { get }
    var prefersLargeTitles: Bool { get }
    var prefersNavigationBarHidden: Bool { get }
}

class NavigationController: UINavigationController {

    override var prefersStatusBarHidden: Bool {
        return viewControllers.last?.prefersStatusBarHidden ?? false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return viewControllers.last?.preferredStatusBarStyle ?? .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: UIColor.white
        ]
        delegate = self
        navigationBar.largeTitleTextAttributes = titleTextAttributes
        navigationBar.prefersLargeTitles = true
        navigationBar.titleTextAttributes = titleTextAttributes
        overrideUserInterfaceStyle = .light
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension NavigationController: UINavigationControllerDelegate {

    // MARK: UINavigationControllerDelegate

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
        ) {

        let configurator = viewController.configuration
        navigationBar.barTintColor = configurator.barTintColor
        setNavigationBarHidden(viewController.prefersNavigationBarHidden, animated: true)
        navigationBar.setBackgroundImage(configurator.navigationBarBackgroundImage, for: .default)
        navigationBar.shadowImage = configurator.shadowImage
        navigationBar.tintColor = configurator.tintColor
        viewController.navigationItem.largeTitleDisplayMode = viewController.prefersLargeTitles ? .always : .never
    }
}

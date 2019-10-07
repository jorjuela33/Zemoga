//
//  Storyboard+Initialization.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import UIKit

extension UIStoryboard {

    enum StoryboardName: String {
        case main = "Main"
    }

    // MARK: Initializers

    convenience init(storyboardName: StoryboardName, bundle: Bundle? = nil) {
        self.init(name: storyboardName.rawValue, bundle: bundle)
    }

    // MARK: Instance methods

    func instantiateViewController<T: UIViewController>() -> T {
        guard let viewController = instantiateViewController(withIdentifier: T.storyboardIdentifier) as? T else {
            fatalError("No view controller found")
        }

        return viewController
    }
}

//
//  Application.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import Application
import UIKit.UIWindow

class Application {
    static let shared = Application()

    // MARK: Instance methods

    func configureMainInterface(in window: UIWindow) {
        let repositoryProvider = RepositoryProvider()
        let navigationController = NavigationController()
        window.rootViewController = navigationController

        let postsWireframe = PostsWireframe(navigationController: navigationController, repositoryProvider: repositoryProvider)
        postsWireframe.toPostsScreen()
        window.makeKeyAndVisible()
    }
}

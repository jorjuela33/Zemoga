//
//  PostsWireframe.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import Domain
import UIKit

protocol PostsWireframeInterface {
    func toPostScreen(withPost post: Post)
    func toPostsScreen()
}

struct PostsWireframe {
    private let navigationController: NavigationController
    private let repositoryProvider: RepositoryProvider
    private let storyBoard: UIStoryboard

    // MARK: Initializers

     init(
        navigationController: NavigationController,
        repositoryProvider: RepositoryProvider,
        storyBoard: UIStoryboard = UIStoryboard(storyboardName: .main)
        ) {

        self.navigationController = navigationController
        self.repositoryProvider = repositoryProvider
        self.storyBoard = storyBoard
    }
}

extension PostsWireframe: PostsWireframeInterface {

    // MARK: PostsWireframeInterface

    func toPostScreen(withPost post: Post) {
        let postWireframe = PostWireframe(navigationController: navigationController, repositoryProvider: repositoryProvider)
        postWireframe.toPostScreen(withPost: post)
    }

    func toPostsScreen() {
        let presenter = PostsPresenter(postsRepository: repositoryProvider.makePostsRepository(), wireframe: self)
        let viewController: PostsViewController = storyBoard.instantiateViewController()

        viewController.presenter = presenter
        navigationController.pushViewController(viewController, animated: false)
    }
}

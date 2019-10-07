//
//  PostCollectionViewCell.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import UIKit

class PostCollectionViewCell: CollectionViewCell {

    @IBOutlet var bodyLabel: UILabel!
    @IBOutlet var readImageView: UIImageView!
}

extension PostCollectionViewCell: CollectionViewConfigurableCell {

    // MARK: CollectionViewConfigurableCell

    func configure(for post: PostDisplayItem) {
        bodyLabel.text = post.body
        readImageView.isHidden = post.read
    }
}

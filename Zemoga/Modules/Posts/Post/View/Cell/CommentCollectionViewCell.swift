//
//  CommentCollectionViewCell.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/6/19.
//

import UIKit

class CommentCollectionViewCell: CollectionViewCell {

    @IBOutlet var commentLabel: UILabel!
}

extension CommentCollectionViewCell: CollectionViewConfigurableCell {

    // MARK: CollectionViewConfigurableCell

    func configure(for comment: CommentDisplayItem) {
        commentLabel.text = comment.body
    }
}

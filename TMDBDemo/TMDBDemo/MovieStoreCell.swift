//
//  MovieStoreCell.swift
//  TMDBDemo
//
//  Created by Agam on 13/09/17.
//  Copyright © 2017 Agam. All rights reserved.
//

import UIKit

class MovieStoreCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView.register(UINib(nibName: "CustomMovieViewCell", bundle: nil), forCellWithReuseIdentifier: "CustomMovieViewCell")
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

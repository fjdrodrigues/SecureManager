//
//  AgentMediaTableViewCell.swift
//  SecureManager
//
//  Created by Fabio on 08/10/2018.
//  Copyright © 2018 Fabio. All rights reserved.
//

import UIKit

class AgentMediaTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var agentMediaCollectionView: UICollectionView!
    
    func setCollectionViewDataSourceDelegate
        <D: UICollectionViewDataSource & UICollectionViewDelegate>
        (dataSourceDelegate: D, forRow row: Int) {
        print("Set Collection View Data Source & Delegate")
        let collectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionViewFlowLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
        agentMediaCollectionView.collectionViewLayout = collectionViewFlowLayout
        agentMediaCollectionView.delegate = dataSourceDelegate
        agentMediaCollectionView.dataSource = dataSourceDelegate
        agentMediaCollectionView.tag = row
        agentMediaCollectionView.contentOffset = .zero
        agentMediaCollectionView.reloadData()
    }
    
}

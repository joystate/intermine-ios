//
//  FavoritesViewController.swift
//  intermine-ios
//
//  Created by Nadia on 5/8/17.
//  Copyright © 2017 Nadia. All rights reserved.
//

import UIKit

class FavoritesViewController: BaseViewController, UITableViewDataSource {
    
    
    @IBOutlet weak var tableView: UITableView?
    private let savedSearches: [FavoriteSearchResult]? = CacheDataStore.sharedCacheDataStore.getSavedSearchResults()

    override func viewDidLoad() {
        super.viewDidLoad()
        super.setNavBarTitle(title: String.localize("Favorites.Title"))
        tableView?.dataSource = self
        tableView?.rowHeight = UITableViewAutomaticDimension
        tableView?.estimatedRowHeight = 140
    }
    
    // MARK: Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let searches = self.savedSearches {
            return searches.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FetchedCell.identifier, for: indexPath) as! FetchedCell
        if let searches = self.savedSearches {
            let search = searches[indexPath.row]
            cell.representedData = search.viewableRepresentation()
        }
        return cell
    }
    
}

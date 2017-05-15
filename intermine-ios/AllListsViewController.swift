//
//  AllListsViewController.swift
//  intermine-ios
//
//  Created by Nadia on 5/14/17.
//  Copyright © 2017 Nadia. All rights reserved.
//

import UIKit

class AllListsViewController: LoadingTableViewController {
    
    private var lists: [List]? = [] {
        didSet {
            if let lists = self.lists {
                if lists.count > 0 {
                    self.tableView.reloadData()
                    self.hideNothingFoundView()
                } else {
                    self.showNothingFoundView()
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let mineUrl = self.mineUrl {
            IntermineAPIClient.fetchLists(mineUrl: mineUrl, completion: { (lists) in
                guard let lists = lists else {
                    self.stopSpinner()
                    self.showNothingFoundView()
                    return
                }
                self.lists = lists
                self.stopSpinner()
            })
        }
    }
    
    // MARK: Load from storyboard
    
    class func allListsViewController(withMineUrl: String) -> AllListsViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "AllListsVC") as? AllListsViewController
        vc?.mineUrl = withMineUrl
        return vc
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let lists = self.lists else {
            return 0
        }
        return lists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ListTableViewCell.identifier, for: indexPath) as! ListTableViewCell
        if let lists = self.lists {
            cell.list = lists[indexPath.row]
        }
        return cell
    }
    
    // MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let lists = self.lists {
            let selectedList = lists[indexPath.row]
            if let selectedType = selectedList.getType() {
                // TODO: based on type, find the views from xml file
                // set value and make request
                if let mineUrl = self.mineUrl {
                    CacheDataStore.sharedCacheDataStore.getParamsForListCall(mineUrl: mineUrl, type: selectedType)
                }
            }
        }
    }

}
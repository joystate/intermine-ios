//
//  AllSearchesViewController.swift
//  intermine-ios
//
//  Created by Nadia on 5/17/17.
//  Copyright © 2017 Nadia. All rights reserved.
//

import UIKit

class FetchedSearchesViewController: LoadingTableViewController, UIGestureRecognizerDelegate, RefineSearchViewControllerDelegate {
    
    @IBOutlet weak var refineButton: UIButton?
    @IBOutlet weak var buttonView: UIView?
    @IBOutlet weak var categoryLabel: UILabel?
    @IBOutlet weak var mineLabel: UILabel?
    
    private var currentOffset: Int = 0
    private var params: [String: String]?
    private let facetManager = FacetManager.shared
    private var mineToSearch: String?
    
    private var facets: [FacetList]? {
        didSet {
            if let facets = self.facets {
                facetManager.updateFacets(facets: facets)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.facetsUpdated), object: self, userInfo: nil)
                var mineNames: [String] = []
                for facet in facets {
                    if let name = facet.getMine() {
                        if !(mineNames.contains(name)) {
                            mineNames.append(name)
                        }
                    }
                }
            }
        }
    }
    
    private var lockData = false {
        didSet {
            if lockData == true {
                AppManager.sharedManager.shouldBreakLoading = true
            }
        }
    }
    
    private var selectedFacet: SelectedFacet? {
        didSet {
            if let selectedFacet = self.selectedFacet {
                categoryLabel?.text = selectedFacet.getFacetName()
                mineLabel?.text = selectedFacet.getMineName()
            }
        }
    }
    
    private var data: [SearchResult] = [] {
        didSet {

            self.data = self.data.sorted(by: { (searchResult0, searchResult1) -> Bool in
                guard let name0 = searchResult0.mineName, let name1 = searchResult1.mineName else {
                    return false
                }
                return name0 < name1
            })
            
            self.data = self.data.sorted(by: { (searchResult0, searchResult1) -> Bool in
                guard let name0 = searchResult0.mineName, let name1 = searchResult1.mineName else {
                    return false
                }
                return name0 == AppManager.sharedManager.selectedMine && name1 != AppManager.sharedManager.selectedMine
            })
            
            self.tableView.reloadData()
            
            if data.count > 0 {
                self.showingResult = true
                self.buttonView?.isHidden = false
            } else {
                
                if self.selectedFacet == nil {
                    self.nothingFound = true
                    self.buttonView?.isHidden = true
                } else {
                    self.nothingFound = true
                    if let buttonView = self.buttonView {
                        self.view.bringSubview(toFront: buttonView)
                    }
                }
            }
        }
    }
    
    // MARK: View controller methods

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavbar()
        self.isLoading = true
        self.loadSearchResultsWithOffset(offset: self.currentOffset)
        refineButton?.setTitle(String.localize("Search.Refine"), for: .normal)
        buttonView?.isHidden = true
        
        if let mineToSearch = self.mineToSearch {
            mineLabel?.text = mineToSearch
        } else {
            mineLabel?.text = String.localize("Search.Refine.AllMines")
        }

        categoryLabel?.text = String.localize("Search.Refine.AllCategories")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //self.lockData = true
        
        if (self.isMovingFromParentViewController || self.isBeingDismissed) {
            self.data = []
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let query = self.params?["q"] {
            navigationItem.title = String.localizeWithArg("Search.Header", arg: query)
        }
    }
    
    // MARK: Load from storyboard
    
    class func fetchedSearchesViewController(withParams: [String: String]?, forMine: String?) -> FetchedSearchesViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "FetchedSearchVC") as? FetchedSearchesViewController
        vc?.params = withParams
        vc?.mineToSearch = forMine
        return vc
    }
    
    // MARK: Private methods
    
    private func configureNavbar() {
        self.navigationController?.navigationBar.barTintColor = UIColor.white//Colors.palma
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.black//Colors.white
        self.navigationController?.navigationBar.backItem?.title = ""
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.black]//Colors.white]
    }

    
    private func loadSearchResultsWithOffset(offset: Int) {
        self.params?["start"] = "\(offset)"
        if let params = self.params {
            if let mineToSearch = self.mineToSearch {
                if let mine = CacheDataStore.sharedCacheDataStore.findMineByName(name: mineToSearch), let url = mine.url {
                    IntermineAPIClient.makeSearchInMine(mineUrl: url, params: params, completion: { (searchResult, facetList, error) in
                        if let searchResult = searchResult {
                            if !self.lockData {
                                self.data.append(searchResult)
                            }
                        }
                        
                        if let facets = facetList {
                            // To later show facets on refine search VC
                            if !self.lockData {
                                self.facets = [facets]
                            }
                        }
                        
                        if let error = error {
                            var info: [String: Any] = [:]
                            info["errorType"] = error
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.searchFailed), object: self, userInfo: info)
                            if let errorMessage = NetworkErrorHandler.getErrorMessage(errorType: error) {
                                self.alert(message: errorMessage)
                            }
                        }
                    })
                }
            } else {
                IntermineAPIClient.makeSearchOverAllMines(params: params) { (searchResults, facetLists, error) in
                    // Transform into [String: String] dict
                    if let searchResults = searchResults {
                        for res in searchResults {
                            if !self.lockData {
                                if !self.data.contains(where: { $0.getId() == res.getId() }) {
                                    self.data.append(res)
                                }
                            }
                        }
                    }
                    
                    if let facets = facetLists {
                        // To later show facets on refine search VC
                        if !self.lockData {
                            self.facets = facets
                        }
                    }
                    
                    if let error = error {
                        var info: [String: Any] = [:]
                        info["errorType"] = error
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.searchFailed), object: self, userInfo: info)
                        if let errorMessage = NetworkErrorHandler.getErrorMessage(errorType: error) {
                            self.alert(message: errorMessage)
                        }
                    }
                }
            }
        }
    }
    
    private func loadRefinedSearchWithOffset(offset: Int, selectedFacet: SelectedFacet) {
        let facetName = selectedFacet.getFacetName()
        if facetName != String.localize("Search.Refine.AllCategories") {
            self.params?["facet_Category"] = selectedFacet.getFacetName()
        }
        
        self.params?["size"] = "\(General.pageSize)"
        self.params?["start"] = "\(offset)"
        
        self.isLoading = true
        
        if let mineName = selectedFacet.getMineName(), let params = self.params {
            if let mine = CacheDataStore.sharedCacheDataStore.findMineByName(name: mineName), let mineUrl = mine.url {
                IntermineAPIClient.makeSearchInMine(mineUrl: mineUrl, params: params, completion: { (searchRes, facetList, error) in
                    
                    if let res = searchRes {
                        self.data.append(res)
                    } else {
                        self.data = []
                    }
                    
                    if let facets = facetList {
                        // To later show facets on refine search VC
                        if let myFacets = self.facets {
                            self.facets = myFacets + [facets]
                        }
                    }
                    
                    if let error = error {
                        if let errorMessage = NetworkErrorHandler.getErrorMessage(errorType: error) {
                            self.alert(message: errorMessage)
                        }
                    }

                })
            }
        }
    }
    
    // MARK: Refine search controller delegate
    
    func refineSearchViewController(controller: RefineSearchViewController, didSelectFacet: SelectedFacet) {
        // reload table view with new data
        self.selectedFacet = didSelectFacet
        //self.showingResult = true
        self.lockData = true
        self.data = []
        self.loadRefinedSearchWithOffset(offset: self.currentOffset, selectedFacet: didSelectFacet)
    }
    
    // MARK: Action
    
    @IBAction func refineSearchTapped(_ sender: Any) {
        if let refineVC = RefineSearchViewController.refineSearchViewController(withFacets: self.facets, mineToSearch: self.mineToSearch) {
            refineVC.delegate = self
            self.navigationController?.pushViewController(refineVC, animated: true)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FetchedCell.identifier, for: indexPath) as! FetchedCell
        cell.data = self.data[indexPath.row]
        return cell
    }
    
    // MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = self.data[indexPath.row]
        if let mineName = data.getMineName(),
            let id = data.getId() {
            if let mine = CacheDataStore.sharedCacheDataStore.findMineByName(name: mineName) {
                if let mineUrl = mine.url {
                    var url = mineUrl + Endpoints.searchResultReport + "?id=\(id)"
                    if let pubmedId = data.getPubmedId() {
                        url = Endpoints.pubmed + pubmedId
                    }
                    if let webVC = WebViewController.webViewController(withUrl: url) {
                        AppManager.sharedManager.shouldBreakLoading = true
                        self.navigationController?.pushViewController(webVC, animated: true)
                    }
                }
            }
        }
    }
    
    // MARK: Scroll view delegate
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        if (maximumOffset - currentOffset <= 10.0) {
            if let selectedFacet = self.selectedFacet, let count = selectedFacet.getCount() {
                if count > General.pageSize, self.currentOffset + General.pageSize < count {
                    self.currentOffset += General.pageSize
                    self.loadRefinedSearchWithOffset(offset: self.currentOffset, selectedFacet: selectedFacet)
                }
            }
        }
    }

}

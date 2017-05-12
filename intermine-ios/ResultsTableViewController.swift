//
//  ResultsTableViewController.swift
//  intermine-ios
//
//  Created by Nadia on 5/11/17.
//  Copyright © 2017 Nadia. All rights reserved.
//

import UIKit
import NVActivityIndicatorView


class ResultsTableViewController: UITableViewController {
    
    private var spinner: NVActivityIndicatorView?
    
    private var templatesList: TemplatesList? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    private var mineUrl: String?
    
    // MARK: Load from storyboard
    
    class func resultsTableViewController(withMineUrl: String) -> ResultsTableViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ResultsTableVC") as? ResultsTableViewController
        vc?.mineUrl = withMineUrl
        return vc
    }

    override func viewDidLoad() {
        //hide table view until info is loaded
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 200
        
        self.configureNavBar()

        self.spinner = NVActivityIndicatorView(frame: self.indicatorFrame(), type: .ballGridPulse, color: Colors.chelseaCucumber, padding: self.indicatorPadding())
        if let spinner = self.spinner {
            self.view.addSubview(spinner)
            self.view.bringSubview(toFront: spinner)
        }
        self.spinner?.startAnimating()
        if let mineUrl = self.mineUrl {
            IntermineAPIClient.fetchTemplates(mineUrl: mineUrl) { (templatesList) in
                guard let list = templatesList else {
                    self.spinner?.stopAnimating()
                    self.alert(message: String.localize("Results.NotFound"))
                    return
                }
                self.templatesList = list
                self.spinner?.stopAnimating()
            }
        }
    }
    
    // MARK: Private methods
    
    private func indicatorFrame() -> CGRect {
        if let navbarHeight = self.navigationController?.navigationBar.frame.size.height, let tabbarHeight = self.tabBarController?.tabBar.frame.size.height {
            let viewHeight = BaseView.viewHeight(view: self.view)
            let indicatorHeight = viewHeight - (tabbarHeight + navbarHeight)
            let indicatorWidth = BaseView.viewWidth(view: self.view)
            return CGRect(x: 0, y: 0, width: indicatorWidth, height: indicatorHeight)
        } else {
            return self.view.frame
        }
    }
    
    private func indicatorPadding() -> CGFloat {
        return BaseView.viewWidth(view: self.view) / 2.5
    }
    
    private func configureNavBar() {
        guard let url = self.mineUrl else {
            return
        }
        if let mine = CacheDataStore.sharedCacheDataStore.findMineByUrl(url: url) {
            self.navigationController?.navigationBar.barTintColor = UIColor.hexStringToUIColor(hex: mine.theme)
            self.navigationController?.navigationBar.isTranslucent = false
            self.navigationController?.navigationBar.tintColor = Colors.white
            self.navigationController?.navigationBar.backItem?.title = ""
            self.navigationController?.navigationBar.topItem?.title = mine.name
            self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: Colors.white]
        }
    }

    // MARK: Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let list = self.templatesList {
            return list.size()
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TemplateTableViewCell.identifier, for: indexPath) as! TemplateTableViewCell
        if let template = templatesList?.templateAtIndex(index: indexPath.row) {
            cell.template = template
        }
        return cell
    }
    
    // MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let template = templatesList?.templateAtIndex(index: indexPath.row),
            let templateDetail = TemplateDetailTableViewController.templateDetailTableViewController(withTemplate: template) {
            self.navigationController?.pushViewController(templateDetail, animated: true)
        }
    }
}
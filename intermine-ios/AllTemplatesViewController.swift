//
//  ResultsTableViewController.swift
//  intermine-ios
//
//  Created by Nadia on 5/11/17.
//  Copyright © 2017 Nadia. All rights reserved.
//

import UIKit


class AllTemplatesViewController: LoadingTableViewController {
    
    private var templatesList: TemplatesList? {
        didSet {
            if let templatesList = self.templatesList {
                if templatesList.size() > 0 {
                    self.tableView.reloadData()
                    self.hideNothingFoundView()
                } else {
                    self.showNothingFoundView()
                }
            }
            
        }
    }
    
    // MARK: Load from storyboard
    
    class func allTemplatesViewController(withMineUrl: String) -> AllTemplatesViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "AllTemplatesVC") as? AllTemplatesViewController
        vc?.mineUrl = withMineUrl
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let mineUrl = self.mineUrl {
            IntermineAPIClient.fetchTemplates(mineUrl: mineUrl) { (templatesList) in
                guard let list = templatesList else {
                    self.stopSpinner()
                    self.showNothingFoundView()
                    return
                }
                self.templatesList = list
                self.stopSpinner()
            }
        }
    }
    
    // MARK: Private methods
    
    

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
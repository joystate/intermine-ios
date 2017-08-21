//
//  SearchResult.swift
//  intermine-ios
//
//  Created by Nadia on 5/17/17.
//  Copyright © 2017 Nadia. All rights reserved.
//

import Foundation


class SearchResult: NSObject {
    
    private var type: String?
    private var fields: [String: AnyObject]?
    var mineName: String?
    private var id: String?
    
    init(withType: String?, fields: [String: AnyObject]?, mineName: String?, id: Int?) {
        self.type = withType
        self.fields = fields
        self.mineName = mineName
        if let id = id {
            self.id = "\(id)"
        }
    }
    
    func getMineName() -> String? {
        return self.mineName
    }
    
    func getId() -> String? {
        return self.id
    }
    
    func getType() -> String? {
        return self.type
    }
    
    func getPubmedId() -> String? {
        if self.type == CategoryType.Publication.rawValue {
            if let pubmedId = self.fields?["pubMedId"] as? String {
                return pubmedId
            }
        }
        return nil
    }
    
    func viewableRepresentation() -> [String: String] {
        var representation: [String: String] = [:]
        if let type = self.type {
            representation["type"] = type
        }
        if let mineName = self.mineName {
            representation["mine"] = mineName
        }
        if let fields = self.fields {
            for (key, value) in fields {
                representation[key] = "\(value)"
            }
        }
        return representation
    }
    
    func isFavorited() -> Bool {
        if let id = self.id {
            if CacheDataStore.sharedCacheDataStore.getSavedSearchById(id: id) != nil {
                return true
            }
        }
        return false
    }
    
}

//
//  UIColor+Methods.swift
//  intermine-ios
//
//  Created by Nadia on 5/10/17.
//  Copyright © 2017 Nadia. All rights reserved.
//

import UIKit

extension UIColor {
    
    class func hexStringToUIColor(hex: String?) -> UIColor {
        guard let hex = hex else {
            return UIColor.gray
        }
        
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    class func gold() -> UIColor? {
        if let img = UIImage(named: "gold") {
            return UIColor(patternImage: img)
        } else {
            return nil
        }
    }
}

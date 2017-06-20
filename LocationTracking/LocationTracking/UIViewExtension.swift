//
//  UIViewExtension.swift
//  LocationTracking
//
//  Created by Nguyen Hai Dang on 6/19/17.
//  Copyright © 2017 Nguyen Hai Dang. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func setupBorder() {
        self.layer.cornerRadius = self.frame.size.height/2
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.clear.cgColor
    }
}
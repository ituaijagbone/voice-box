//
//  PaddingLabel.swift
//  Box
//
//  Created by Itua Ijagbone on 1/8/16.
//  Copyright © 2016 Itua Ijagbone. All rights reserved.
//

import UIKit

class PaddingLabel: UILabel {
    static let Top:CGFloat = 0.0
    static let Left:CGFloat = 0.0
    static let Bottom:CGFloat = 8.0
    static let Right:CGFloat = 0.0
    
    let padding = UIEdgeInsets(top: Top, left: Left, bottom: Bottom, right: Right)
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, padding))
    }
    
    override func intrinsicContentSize() -> CGSize {
        var size = super.intrinsicContentSize()
        size.width += self.padding.left + self.padding.right
        size.height += self.padding.top + self.padding.bottom
        return size
    }

}

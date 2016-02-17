//
//  VoiceLayout.swift
//  Box
//
//  Created by Itua Ijagbone on 1/4/16.
//  Copyright © 2016 Itua Ijagbone. All rights reserved.
//

import UIKit

protocol VoiceLayoutDelegate {
    func collectionView(collectionView: UICollectionView, heightForTitleAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat
    
    func collectionView(collectionView: UICollectionView, heightForNoteAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat
}

class VoiceLayoutAttributes: UICollectionViewLayoutAttributes {
    var noteHeight: CGFloat = 0.0
    var titleHeight: CGFloat = 0.0
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone) as! VoiceLayoutAttributes
        copy.noteHeight = noteHeight
        copy.titleHeight = titleHeight
        return copy
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let attributes = object as? VoiceLayoutAttributes {
            if (attributes.noteHeight == noteHeight) {
                return super.isEqual(object)
            }
            
//            if (attributes.titleHeight == titleHeight) {
//                return super.isEqual(object)
//            }
        }
        return false
    }
}

class VoiceLayout: UICollectionViewLayout {
    var delegate:VoiceLayoutDelegate!
    
    var numberOfColumns = 2
    var cellPadding:CGFloat = 6.0
    
    private var cache = [VoiceLayoutAttributes]()
    
    private var contentHeight:CGFloat = 0.0
    private var contentWidth:CGFloat {
        let insets = collectionView!.contentInset
        return CGRectGetWidth(collectionView!.bounds) - (insets.left + insets.right)
    }
    
    override class func layoutAttributesClass() -> AnyClass {
        return VoiceLayoutAttributes.self
    }
    
    override func prepareLayout() {
        if cache.isEmpty {
            let columnWidth:CGFloat = contentWidth / CGFloat(numberOfColumns)
            var xOffset = [CGFloat]()
            for column in 0 ..< numberOfColumns {
                xOffset.append(CGFloat(column) * columnWidth)
            }
        
            var column = 0
            var yOffset = [CGFloat](count: numberOfColumns, repeatedValue: 0)
            
            for item in 0 ..< collectionView!.numberOfItemsInSection(0) {
                let indexPath = NSIndexPath(forItem: item, inSection: 0)
                
                let width = columnWidth - cellPadding * 2
                
                var titleHeight = delegate.collectionView(collectionView!, heightForTitleAtIndexPath: indexPath, withWidth: width)
                
                let noteHeight = delegate.collectionView(collectionView!, heightForNoteAtIndexPath: indexPath, withWidth: width)
                
                let attributes = VoiceLayoutAttributes(forCellWithIndexPath: indexPath)
                attributes.noteHeight = noteHeight
                attributes.titleHeight = titleHeight
                
                if titleHeight == 0.0 {
                    titleHeight = 21.0
                }
                let height = cellPadding + cellPadding + titleHeight + cellPadding +  noteHeight + cellPadding + 21.0
                let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
                let insetFrame = CGRectInset(frame, cellPadding, cellPadding)
                attributes.frame = insetFrame
                
                cache.append(attributes)
                
                contentHeight = max(contentHeight, CGRectGetMaxY(frame))
                yOffset[column] = yOffset[column] + height
                column = column >= (numberOfColumns - 1) ? 0 : ++column
                
            }
        }
    }
    
    override func collectionViewContentSize() -> CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes] {
        
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        
        for attributes in cache {
            if CGRectIntersectsRect(attributes.frame, rect) {
                layoutAttributes.append(attributes)
            }
        }
        
        return layoutAttributes
    }
    
    func clearCache() {
        cache.removeAll(keepCapacity: false)
    }
}

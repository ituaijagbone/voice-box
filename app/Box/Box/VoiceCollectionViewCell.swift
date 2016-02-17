//
//  VoiceCollectionViewCell.swift
//  Box
//
//  Created by Itua Ijagbone on 1/4/16.
//  Copyright © 2016 Itua Ijagbone. All rights reserved.
//

import UIKit

protocol VoiceCollectionViewCellDelegate {
    func callSegueFromCell(data voice: AnyObject)
    func playAudio(collectionViewCell: VoiceCollectionViewCell, withAudio audio: String) -> Bool
    func stopAudio()
}

class VoiceCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var noteTextView: UITextView!
    @IBOutlet var noteViewHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet var titleViewHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet var playButton: UIButton!
    
    var isPlaying = false
    
    var delegate: VoiceCollectionViewCellDelegate!
    
    var voice: Voice? {
        didSet {
            if let voice = voice {
                clearTexts()
                if voice.title.isEmpty {
//                    titleViewHeightLayoutConstraint.constant = CGFloat(0.0)
                } else {
                    titleLabel.text = voice.title
//                    titleViewHeightLayoutConstraint.constant = CGFloat(21.0)
                }
//                titleLabel.text = voice.title
                noteTextView.text = voice.note
                let tap = UITapGestureRecognizer(target: self, action: Selector("handleNoteTap:"))
                noteTextView.addGestureRecognizer(tap)
                textAttr()
            }
        }
    }
    
    func textAttr() {
        titleLabel.textColor = .whiteColor()
    }
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        super.applyLayoutAttributes(layoutAttributes)
        if let attributes = layoutAttributes as? VoiceLayoutAttributes {
            noteViewHeightLayoutConstraint.constant = attributes.noteHeight
            titleViewHeightLayoutConstraint.constant = attributes.titleHeight
        }
    }
    
    @IBAction func playAudio(sender: UIButton) {
        guard let voice = self.voice else {
            return
        }
        
        if !isPlaying {
            if delegate.playAudio(self, withAudio: voice.audio) {
                playButton.setTitle("stop", forState: .Normal)
                isPlaying = true
            }
        } else {
            delegate.stopAudio()
        }
        
    }
    
    func clearTexts() {
        titleLabel.text = ""
        noteTextView.text = ""
    }
    
    func handleNoteTap(sender: UITapGestureRecognizer) {
        if let data = voice {
            delegate.callSegueFromCell(data: data)
        }
    }
    
    func notifyPlayToStop() {
        dispatch_async(dispatch_get_main_queue()) {
            self.playButton.setTitle("Play", forState: .Normal)
            self.isPlaying = false
        }
    }
}

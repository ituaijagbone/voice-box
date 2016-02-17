//
//  NoteViewController.swift
//  Box
//
//  Created by Itua Ijagbone on 1/5/16.
//  Copyright © 2016 Itua Ijagbone. All rights reserved.
//

import UIKit
import AVFoundation

class NoteViewController: UIViewController {
    
    var voice: Voice! = nil
    var audioPlayer: AVAudioPlayer!
    var audioEngine: AVAudioEngine!
    
    var isPlaying = false
    var isNoteEditing = false
    private let hashtag = "spotify"
    private var restartAudioVal: NSTimeInterval = 0
    
    
    @IBOutlet var titleNavigationItem: UINavigationItem!
    @IBOutlet var playBarButtonItem: UIBarButtonItem!
    @IBOutlet var noteTextView: UITextView!
    @IBOutlet var editButton: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        guard (voice != nil) else {
            return
        }
        
        titleNavigationItem.title = voice.title
        noteTextView.text = voice.note
        noteTextView.attributedText = getAttributedString(withText: voice.note)
        noteTextView.delegate = self
        
        guard let filePathURL = BoxUtility.getAudioURL(filename: voice.audio) else {
            return
        }
        
        guard let audioPlayer = BoxUtility.setupAudioPlayerWithNSURL(filePathURL) else {
            return
        }
        
        self.audioPlayer = audioPlayer
        self.audioPlayer.delegate = self
        self.audioEngine = AVAudioEngine()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func playButton(sender: UIBarButtonItem) {
        if isPlaying {
            pauseAudio()
            isPlaying = false
            let playItem = UIBarButtonItem(barButtonSystemItem: .Play, target: self, action: "playButton:")
            titleNavigationItem.rightBarButtonItems?[0] = playItem
        } else {
            playAudio()
            isPlaying = true
            let playItem = UIBarButtonItem(barButtonSystemItem: .Pause, target: self, action: "playButton:")
            let stopItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: "stopButton:")
            titleNavigationItem.rightBarButtonItems?[0] = playItem
            if titleNavigationItem.rightBarButtonItems?.count > 2 {
                titleNavigationItem.rightBarButtonItems?.removeAtIndex(1)
            }
            titleNavigationItem.rightBarButtonItems?.insert(stopItem, atIndex: 1)
        }
    }
    
    @IBAction func stopButton(sender: UIBarButtonItem) {
        stopAudio()
        isPlaying = false
        let playItem = UIBarButtonItem(barButtonSystemItem: .Play, target: self, action: "playButton:")
        titleNavigationItem.rightBarButtonItems?[0] = playItem
        titleNavigationItem.rightBarButtonItems?.removeAtIndex(1)
    }
    
    
    @IBAction func editNoteButton(sender: UIBarButtonItem) {
        if isNoteEditing {
            isNoteEditing = false
            noteTextView.editable = false
            stopAudio()
            // TODO: save note
            voice.note = noteTextView.attributedText.string
            noteTextView.attributedText = getAttributedString(withText: voice.note)
            voice.saveInBackgroundWithBlock{
                (success: Bool, error: NSError?) -> Void in
                if success {
                    print("saved successfully")
                    
                } else {
                    print("error saving voice to Parse: \(error?.description)")
                }
                let editItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "editNoteButton:")
                self.editButton.items?[0] = editItem
            }
        } else {
            // if its done saving to parse set editable to true. else show some form of message
            isNoteEditing = true
            noteTextView.editable = true
            // TODO: stop playing audio
            stopAudio()
            let editItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "editNoteButton:")
            editButton.items?[0] = editItem
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "spotifyIdentifier" {
            let navVC = segue.destinationViewController as! UINavigationController
            let spotifyVC = navVC.topViewController as! SpotifyViewController
            spotifyVC.query = sender as! String
        }
    }
    
    func getAttributedString(withText text: String) -> NSMutableAttributedString {
        
        let noteString:NSString = text
        let words:[NSString] = noteString.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        let attrs:[String : AnyObject] = [
            NSFontAttributeName : UIFont(name: "HelveticaNeue-Light", size: 14.0)!
        ]
        let noteAttributedString = NSMutableAttributedString(string: text, attributes: attrs)
        
        var progress = 0
        
        for word in words {
            var scheme: String? = nil
            
            if word.hasPrefix("@") {
                scheme = hashtag
            }
            
            if let scheme = scheme {
                var word_t:String = word as String
                let prefix = word_t[word_t.startIndex]
                word_t.removeAtIndex(word_t.startIndex)
                
                if !word_t.isEmpty {
                    let prefixWord = "\(prefix)\(word_t)"
                    let remainingRange = NSRange(location: progress, length: noteString.length - progress)
                    let matchRange = noteString.rangeOfString(prefixWord, options: NSStringCompareOptions.LiteralSearch, range: remainingRange)
                    if let spotifyString = word_t.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet()) {
                        noteAttributedString.addAttribute(NSLinkAttributeName, value: "\(scheme):\(spotifyString)", range: matchRange)
                    }
                }
            }
            
            progress += word.length + 1
        }
        
        return noteAttributedString
    }

}

extension NoteViewController:UITextViewDelegate {
    func processLink(link: String) -> String{
        var text =  ""
        
        for index in link.characters.indices {
            let t:String = "\(link[index])"
            if t.lowercaseString != t {
                text = "\(text) \(t)"
            } else {
                text = "\(text)\(t)"
            }
        }
        
        text = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        if let rangeBy = text.rangeOfString("By"){
            let progress = text.startIndex.distanceTo(rangeBy.endIndex) + 1
            let index = text.startIndex.advancedBy(progress)
            let postBy = text.substringFromIndex(index)
            let splitPostBy = postBy.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            var artist = ""
            for word in splitPostBy {
                if word == "And" {
                    artist = "\(artist) \(word) "
                } else {
                    artist = "\(artist)\(word)"
                }
            }
            
            text = text.substringToIndex(rangeBy.startIndex)
            
//            let preBy = text.substringToIndex(index)
////            text = preBy + artist
        }
        return text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
    func promptSpotifyAlert(message: String) {
        let title = "Search Spotify"
        let actionAlert = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
        
        let dismissHandler = {
            (action: UIAlertAction!) in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        let playHandler = {
            (action: UIAlertAction!) in
            self.performSegueWithIdentifier("spotifyIdentifier", sender: message)
        }
        actionAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: dismissHandler))
        actionAlert.addAction(UIAlertAction(title: "Search", style: .Default, handler: playHandler))
        presentViewController(actionAlert, animated: true, completion: nil)
    }
    
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        if URL.scheme == hashtag {
            promptSpotifyAlert(processLink(URL.resourceSpecifier.stringByRemovingPercentEncoding!))
        }
        
        return false
    }
}

extension NoteViewController: AVAudioPlayerDelegate {
    func playAudio() {
        guard self.audioPlayer != nil else {
            return
        }
        
        self.audioPlayer.play()
    }
    
    func stopAudio() {
        if self.audioPlayer != nil {
            self.audioPlayer.stop()
            self.audioPlayer.currentTime = restartAudioVal
        }
        if self.audioEngine != nil {
            self.audioEngine.stop()
            self.audioEngine.reset()
        }
    }
    
    func pauseAudio() {
        if self.audioPlayer != nil {
            self.audioPlayer.pause()
        }
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            stopButton(UIBarButtonItem())
        } else {
            playButton(UIBarButtonItem())
        }
    }
}
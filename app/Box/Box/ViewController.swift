//
//  ViewController.swift
//  Box
//
//  Created by Itua Ijagbone on 12/31/15.
//  Copyright © 2015 Itua Ijagbone. All rights reserved.
//

import UIKit
import AVFoundation
import Parse

class ViewController: UIViewController {
    var voices = [Voice]()
    
    @IBOutlet var collectionView: UICollectionView!
    private let reuseIdentifier = "VoiceCell"
    private let voiceToNoteSegue = "VoiceToNoteSegue"
    private var restartAudioVal: NSTimeInterval = 0
    
    var audioPlayer: AVAudioPlayer!
    var audioEngine: AVAudioEngine!
    var audioFile: AVAudioFile!
    var currentCollectionCell: VoiceCollectionViewCell!
    
    private let sectionInsets = UIEdgeInsets(top: 23.0, left: 5.0, bottom: 50.0, right: 5.0)
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        collectionView.autoresizingMask = .FlexibleHeight
        collectionView.delegate = self
        collectionView.dataSource = self
        if let layout = self.collectionView?.collectionViewLayout as? VoiceLayout {
            layout.delegate = self
        }
        
        self.collectionView.contentInset = UIEdgeInsets(top: 23, left: 5, bottom: 10, right: 5)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.allVoices()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func refresh(sender: AnyObject) {
        allVoices()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if audioPlayer != nil {
            audioPlayerDidFinishPlaying(audioPlayer, successfully: true)
        }
        
        if let identifier = segue.identifier {
            if identifier == voiceToNoteSegue, let indexPath = sender as? NSIndexPath, let destinationVC = segue.destinationViewController as? NoteViewController {
                let voice = voices[indexPath.item]
                destinationVC.voice = voice
            }
            
            if identifier == voiceToNoteSegue, let voice = sender as? Voice, let destinationVC = segue.destinationViewController as? NoteViewController {
                destinationVC.voice = voice
            }
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        refreshLayout()
    }
    
    func allVoices() {
        let query = Voice.query()
        query?.findObjectsInBackgroundWithBlock{
            (objects: [PFObject]?, error: NSError?) -> Void in
            if let objects = objects as? [Voice] {
                self.voices =  objects
                self.refreshLayout()
            }
        }
    }
    
    func refreshLayout() {
        if let layout = self.collectionView?.collectionViewLayout as? VoiceLayout {
            layout.clearCache()
            layout.delegate = self
            
            if UIDevice.currentDevice().orientation.isLandscape.boolValue {
                layout.numberOfColumns = 3
            } else {
                layout.numberOfColumns = 2
            }
            
            self.collectionView.reloadData()
        }
    }

}

extension ViewController:UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return voices.count;
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! VoiceCollectionViewCell
        cell.voice = voices[indexPath.item]
        
        let shadowOffsetWidth: Int = 0
        let shadowOffsetHeight: Int = 3
        let shadowColor: UIColor? = UIColor.blackColor()
        let shadowOpacity: Float = 0.4
        
        let shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 2)
        cell.layer.masksToBounds = false
        cell.layer.shadowColor = shadowColor?.CGColor
        cell.layer.shadowOffset = CGSize(width: shadowOffsetWidth, height: shadowOffsetHeight);
        cell.layer.shadowOpacity = shadowOpacity
        cell.layer.shadowPath = shadowPath.CGPath
        
        cell.delegate = self
        
        return cell
    }
}

extension ViewController: VoiceLayoutDelegate {
    func collectionView(collectionView: UICollectionView, heightForTitleAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat {
        let voice = voices[indexPath.item]
        
        if voice.title.isEmpty {
            return CGFloat(0)
        }
        let titlePadding = CGFloat(4)
        let font = UIFont(name: "HelveticaNeue-Light", size: 17)!
        let titleHeight = voice.heightForTitle(font, width: width)
        let height = (2 * titlePadding) + titleHeight + titlePadding
        return height
    }
    
    func collectionView(collectionView: UICollectionView, heightForNoteAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat {
        let voice = voices[indexPath.item]
//        let notePadding = CGFloat(4)
//        let noteFooterHeight = CGFloat(27)
        let font = UIFont(name: "HelveticaNeue-Light", size: 14)!
        let noteHeight = voice.heightForNote(font, width: width)
        let height = noteHeight
        return height
    }
}

extension ViewController:UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(voiceToNoteSegue, sender: indexPath)
    }
}

extension ViewController:VoiceCollectionViewCellDelegate, AVAudioPlayerDelegate {
    func callSegueFromCell(data voice: AnyObject) {
        if let v = voice as? Voice {
            performSegueWithIdentifier(voiceToNoteSegue, sender: v)
        }
    }
    
    func playAudio(audio audio: String) -> Bool{
        stopAudio()
        
        guard let filePathUrl = BoxUtility.getAudioURL(filename: audio) else {
            return false
        }
        
        guard let audioPlayer = BoxUtility.setupAudioPlayerWithNSURL(filePathUrl) else {
            return false
        }
        self.audioPlayer = audioPlayer
        self.audioPlayer.delegate = self
        
        if self.audioEngine == nil {
          self.audioEngine = AVAudioEngine()
        }
        self.audioPlayer.play()
        return true
    }
    
    func playAudio(collectionViewCell: VoiceCollectionViewCell, withAudio audio: String) -> Bool{
        stopAudio()
        
        guard let filePathUrl = BoxUtility.getAudioURL(filename: audio) else {
            return false
        }
        
        guard let audioPlayer = BoxUtility.setupAudioPlayerWithNSURL(filePathUrl) else {
            return false
        }
        currentCollectionCell = collectionViewCell
        self.audioPlayer = audioPlayer
        self.audioPlayer.delegate = self
        
        if self.audioEngine == nil {
            self.audioEngine = AVAudioEngine()
        }
        
        self.audioPlayer.play()
        return true
    }

    
    func stopAudio() {
        if self.currentCollectionCell != nil {
            self.currentCollectionCell.notifyPlayToStop()
            self.currentCollectionCell = nil
        }
        if self.audioPlayer != nil {
            self.audioPlayer.stop()
            self.audioPlayer.currentTime = restartAudioVal
        }
        if self.audioEngine != nil {
            self.audioEngine.stop()
            self.audioEngine.reset()
        }
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        stopAudio()
    }
}


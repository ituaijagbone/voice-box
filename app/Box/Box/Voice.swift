//
//  Voice.swift
//  Box
//
//  Created by Itua Ijagbone on 1/3/16.
//  Copyright © 2016 Itua Ijagbone. All rights reserved.
//

import UIKit
import Parse

protocol VoiceDelegate {
    func reloadVoice(withData voices: [Voice])
}

class Voice: PFObject, PFSubclassing {
    static private let CLASS_NAME = "Voice"
//    var delegate: VoiceDelegate!
    
//    class func allVoices() {
//        let query = Voice.query()
//        query?.findObjectsInBackgroundWithBlock{
//            (objects: [PFObject]?, error: NSError?) -> Void in
//            if let objects = objects as? [Voice] {
//                Voice().delegate.reloadVoice(withData: objects)
//            }
//        }
//    }
    
    class func exportVoices() {
        var voices = [Voice]()
        if let URL = NSBundle.mainBundle().URLForResource("Voices", withExtension: "plist") {
            if let voicesFromPlist = NSArray(contentsOfURL: URL) {
                for dictionary in voicesFromPlist {
                    let voice = Voice(dictionary: dictionary as! NSDictionary)
                    voices.append(voice)
                }
            }
        }
        
        PFObject.saveAllInBackground(voices) {
            (success: Bool, error: NSError?) -> Void in
            if success {
                print("export was successful")
            } else {
                print("export failed \(error?.description)")
            }
        }
    }
    
    @NSManaged var title: String
    @NSManaged var note: String
    @NSManaged var voiceType: String
    @NSManaged var audio: String
    
    override class func initialize() {
        struct Static {
            static var onceToken: dispatch_once_t = 0
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    override init() {
        super.init()
    }
    
    convenience init(title: String, note: String, voiceType: String, audio: String) {
        self.init()
        
        self.title = title
        self.note = note
        self.voiceType = voiceType
        self.audio = audio
        
        
    }
    
    convenience init(dictionary: NSDictionary) {
        let title = dictionary["title"] as? String
        let note = dictionary["note"] as? String
        let voiceType = dictionary["type"] as? String
        let audio = dictionary["audio"] as? String
        self.init(title: title!, note: note!, voiceType: voiceType!, audio: audio!)
    }
    
    static func parseClassName() -> String {
        return self.CLASS_NAME
    }
    
    func heightForTitle(font: UIFont, width: CGFloat) -> CGFloat {
        if self.title.isEmpty {
            return CGFloat(0)
        }
        let rect = NSString(string: self.title).boundingRectWithSize(CGSize(width: width, height: CGFloat(MAXFLOAT)), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        return ceil(rect.height)
    }
    
    func heightForNote(font: UIFont, width: CGFloat) -> CGFloat {
        let rect = NSString(string: self.note).boundingRectWithSize(CGSize(width: width, height: CGFloat(MAXFLOAT)), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        return ceil(rect.height)
    }
}

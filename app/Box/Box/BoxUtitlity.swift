//
//  BoxUtitlity.swift
//  Box
//
//  Created by Itua Ijagbone on 1/12/16.
//  Copyright © 2016 Itua Ijagbone. All rights reserved.
//

import Foundation
import AVFoundation

class BoxUtility {

    class func getAudioURL(filename filename: String) -> NSURL?{
        let directoryPath = getDocumentDirectory()
        let pathArray = [directoryPath, filename]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)
        return filePath
    }

    class func getDocumentDirectory() -> String {
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentDirectory = path[0]
        return documentDirectory
    }

    class func setupAudioPlayerWithNSURL(recordedAudioUrl: NSURL) -> AVAudioPlayer? {
        do {
            let audioPlayer = try AVAudioPlayer(contentsOfURL: recordedAudioUrl)
            audioPlayer.enableRate = true
            return audioPlayer
        } catch {
            return nil
        }
    }

    class func getHostURL() -> String {
        return "http://localhost:2000"
    }
    class func getAudioURL() -> String {
        return "http://localhost:2000/audio"
    }
}

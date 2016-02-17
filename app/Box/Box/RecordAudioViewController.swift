//
//  RecordAudioViewController.swift
//  Box
//
//  Created by Itua Ijagbone on 1/10/16.
//  Copyright © 2016 Itua Ijagbone. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire
import SwiftyJSON

class RecordAudioViewController: UIViewController {
    
    @IBOutlet var recordingInProgress: UILabel!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var stopButton: UIButton!
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var renameButton: UIBarButtonItem!
    @IBOutlet var recordToolBar: UIToolbar!
    @IBOutlet var recordAudioNavigationItem: UINavigationItem!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var isAllowedToRecord = false
    private let tapToRecordText = "Tap to Record"
    private let tapToReRecordText = "Tap to Re-Record else Save"
    private let recordingInProgressText = "Recording in Progress"
    private let recordPerMissionText = "Can't record audio, please change permission setting"
    private let recordErrorText = "Can't record audio. Error setting up recording session"
    private var recordingName: String!
    private var recordingTitle = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        recordingSession = AVAudioSession.sharedInstance()
        recordingName = generateFileName()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] (allowed: Bool) -> Void in
                dispatch_async(dispatch_get_main_queue()){
                    if allowed {
                        self.isAllowedToRecord = true
                        self.loadRecordingUI()
                    } else {
                        self.recordingInProgress.text = self.recordPerMissionText
                    }
                }
                
            }
        } catch {
            self.recordingInProgress.text = recordErrorText
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        stopButton.hidden = true
        recordButton.hidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelRecording(sender: AnyObject) {
        // TODO: I think I am to delete file here
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func saveRecording(sender: AnyObject) {
        
        let recordDirPath = RecordAudioViewController.getDocumentsDirectory()
        let recordingName:String = self.recordingName
        let pathArray = [recordDirPath, recordingName]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)
        let musicData = NSData(contentsOfURL: filePath!)
        
        let metadata = [
            "title": self.recordingTitle,
            "note" : "",
            "type" : "voice",
            "audio": self.recordingName
        ]
        
        let voice = Voice(dictionary: metadata)
//        // save to parse
//        voice.saveInBackgroundWithBlock{
//            (success: Bool, error: NSError?) -> Void in
//            if success {
//                print("saved successfully")
//            } else {
//                print("error saving voice to Parse: \(error?.description)")
//            }
//            self.dismissViewControllerAnimated(true, completion: nil)
//        }
        // send to server
        
        Alamofire.upload(.POST, BoxUtility.getAudioURL(), multipartFormData: { multipartFormData in
                if let musicData = musicData {
                    multipartFormData.appendBodyPart(data: musicData, name: "file", fileName: self.recordingName, mimeType: "audio/x-wav")
                }
            },
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.responseJSON { response in
                        if let value = response.result.value {
                            let result = JSON(value)
                            print(result)
                            if let status = result["status"].string {
                                if status == "success" {
                                    voice.note = result["annotation"].stringValue
                                } else {
                                     print("transcribing failed")
                                }
                            }
                            
                            voice.saveInBackgroundWithBlock{
                                (success: Bool, error: NSError?) -> Void in
                                if success {
                                    print("saved successfully")
                                } else {
                                    print("error saving voice to Parse: \(error?.description)")
                                }
                                self.dismissViewControllerAnimated(true, completion: nil)
                            }
                        }
                    }
                case .Failure(let encodingError):
                    print(encodingError)
                    voice.saveInBackgroundWithBlock{
                        (success: Bool, error: NSError?) -> Void in
                        if success {
                            print("saved successfully")
                        } else {
                            print("error saving voice to Parse: \(error?.description)")
                        }
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                }
        })
    }
    
    @IBAction func recordButton(sender: AnyObject) {
        recordingInProgress.text = recordingInProgressText
        recordButton.hidden = true
        stopButton.hidden = false
        
        let recordDirPath = RecordAudioViewController.getDocumentsDirectory()
        let recordingName:String = self.recordingName
        let pathArray = [recordDirPath, recordingName]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)
        
        let settings = [
            "" : ""
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(URL: filePath!, settings: settings)
            audioRecorder.delegate = self
            
            if audioRecorder.prepareToRecord() {
                audioRecorder.record()
            } else {
                finishRecording(success: false)
            }
        } catch {
            finishRecording(success: false)
        }
    }
    
    @IBAction func stopAudio(sender: AnyObject) {
        audioRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
            finishRecording(success: true)
        } catch _ {
            finishRecording(success: false)
        }
    }
    
    @IBAction func renameRecording(sender: UIBarButtonItem) {
        let renameAlert = UIAlertController(title: "Rename Audio", message: "Rename Audio Recording", preferredStyle: .Alert)
    
        renameAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        renameAlert.addAction(UIAlertAction(title: "Rename", style: .Default, handler: nil))
        
        renameAlert.addTextFieldWithConfigurationHandler{ (textField: UITextField) in
            textField.placeholder = "Change name"
            textField.delegate = self
            textField.tag = 1
        }
        
        self.presentViewController(renameAlert, animated: true, completion: nil)
    }
    
    func generateFileName() -> String {
        let dateFormatter = NSDateFormatter()
        let currentDate = NSDate()
        dateFormatter.dateFormat = "dd-MM-yy_HH:mm:ss"
        return "\(dateFormatter.stringFromDate(currentDate)).wav"
    }
    
    func loadRecordingUI() {
        dispatch_async(dispatch_get_main_queue()) {
            self.recordButton.hidden = false
            self.recordingInProgress.text = self.tapToRecordText
        }
    }
    
    func finishRecording(success success: Bool) {
        if audioRecorder != nil {
            audioRecorder.stop()
            audioRecorder = nil
        }
        
        if success {
            recordingInProgress.text = tapToReRecordText
        } else {
            recordingInProgress.text = tapToRecordText
        }
        
        recordButton.hidden = false
        stopButton.hidden = true
    }
    
    class func getDocumentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension RecordAudioViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            finishRecording(success: true)
        } else {
            finishRecording(success: false)
        }
    }
}

extension RecordAudioViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.tag == 1 {
            if let rTitle = textField.text where !rTitle.isEmpty {
                self.recordingTitle = rTitle
                self.recordAudioNavigationItem.title = rTitle
            }
        }
    }
}
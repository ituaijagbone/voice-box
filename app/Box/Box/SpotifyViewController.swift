//
//  SpotifyViewController.swift
//  Box
//
//  Created by Itua Ijagbone on 2/17/16.
//  Copyright © 2016 Itua Ijagbone. All rights reserved.
//

import UIKit

class SpotifyViewController: UITableViewController {

    var query:String!
    var tracks = [SPTPartialTrack]()
    
    let kClientID = "fc024a4fcb4b4f19bcf223c4483312c1"
    let kCallbackURL = "voice-box://"
    let kTokenSwapURL = "http://localhost:1234/swap"
    let kTokenRefreshURL = "http://localhost:1234/refresh"
    let kSessionObjectDefaultsKey = "kSessionObjectDefaultsKey"
    
    var player: SPTAudioStreamingController?
    let spotifyAuthenticator = SPTAuth.defaultInstance()
    var session: SPTSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isAuthenticated() {
            loginToSpotify()
        } else {
            self.spotifyAuth()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tracks.count
    }
    @IBAction func stopSpotifyPlayer(sender: AnyObject) {
        // TODO: Stop the spotify player
        if let player = self.player {
            player.stop(nil)
        }
        
    }

    @IBAction func closeSpotify(sender: AnyObject) {
        // TODO: Stop the player
        if let player = self.player {
            player.stop(nil)
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showPrompt(message: String) {
        let actionAlert = UIAlertController(title: "Alert", message: message, preferredStyle: .Alert)
        let dismissHandler = {
            (action: UIAlertAction!) in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        actionAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: dismissHandler))
        presentViewController(actionAlert, animated: true, completion: nil)
    }
    
    func isAuthenticated() -> Bool {
        if let data: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey(kSessionObjectDefaultsKey) {
            session = NSKeyedUnarchiver.unarchiveObjectWithData(data as! NSData) as? SPTSession
            if let status = session?.isValid() {
                return status
            }
        }
        return false
    }
    
    func spotifyAuth() {
        self.spotifyAuthenticator.clientID = self.kClientID
        self.spotifyAuthenticator.requestedScopes = [SPTAuthStreamingScope]
        self.spotifyAuthenticator.redirectURL = NSURL(string: self.kCallbackURL)
        self.spotifyAuthenticator.tokenSwapURL = NSURL(string: self.kTokenSwapURL)
        self.spotifyAuthenticator.tokenRefreshURL = NSURL(string: self.kTokenRefreshURL)
        
        let spotifyAuthenticationViewController = SPTAuthViewController.authenticationViewController()
        spotifyAuthenticationViewController.delegate = self
        spotifyAuthenticationViewController.modalPresentationStyle = .OverCurrentContext
        spotifyAuthenticationViewController.definesPresentationContext = true
        self.presentViewController(spotifyAuthenticationViewController, animated: false, completion: nil)
    }
    
    func loginToSpotify() {
        setupSpotifyPlayer()
        loginWithSpotifySession(self.session!)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)
        
        // Configure the cell...
        let partialTrack = tracks[indexPath.row]
        var artists = ""
        if partialTrack.artists.count > 1 {
            for i in 0...(partialTrack.artists.count-2) {
                artists += "\(partialTrack.artists[i].name!), "
            }
            artists += "\(partialTrack.artists.last!.name!)"
        } else {
            artists = "\(partialTrack.artists.first!.name!)"
        }
        cell.textLabel?.text = partialTrack.name
        cell.detailTextLabel?.text = artists
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let player = self.player {
            player.stop(nil)
            let partialTrack = tracks[indexPath.row]
            player.playURIs([partialTrack.playableUri], withOptions: nil, callback: {(error) in
                if error != nil {
                    self.showPrompt("\(error)")
                }
            })
        }
    }


}

extension SpotifyViewController: SPTAuthViewDelegate {
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didFailToLogin error: NSError!) {
        showPrompt("Login failed")
    }
    
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didLoginWithSession session: SPTSession!) {
        let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
        NSUserDefaults.standardUserDefaults().setObject(sessionData, forKey: kSessionObjectDefaultsKey)
        NSUserDefaults.standardUserDefaults().synchronize()
        self.session = session
        loginToSpotify()
    }
    
    func authenticationViewControllerDidCancelLogin(authenticationViewController: SPTAuthViewController!) {
        showPrompt("login canceled")
    }
    
}

extension SpotifyViewController: SPTAudioStreamingPlaybackDelegate {
    func setupSpotifyPlayer() {
        player = SPTAudioStreamingController(clientId: spotifyAuthenticator.clientID)
        player!.playbackDelegate = self
        player!.diskCache = SPTDiskCache(capacity: 1024 * 1024 * 64)
    }
    
    func loginWithSpotifySession(session: SPTSession) {
        player?.loginWithSession(session, callback: { (error: NSError!) in
            if error != nil {
                self.showPrompt("Couldn't login with session:\(error)")
                return
            }
        })
        self.useLoggedInPermissions()
    }
    
    func useLoggedInPermissions() {
        SPTSearch.performSearchWithQuery(self.query, queryType: SPTSearchQueryType.QueryTypeTrack, offset:3 as NSInteger, accessToken: nil, callback: { (error, result) in
            if error != nil {
                self.showPrompt("Can't find song \(error)")
                return
            }
            
            if let list = result as? SPTListPage {
                if list.items == nil {
                    self.showPrompt("Can't find song")
                    return
                }
                self.tracks = list.items as! [SPTPartialTrack]
                self.tableView.reloadData()
            } else {
                self.showPrompt("error thrown")
            }
        })
        //        let spotifyURI = "spotify:track:1WJk986df8mpqpktoktlce"
        //        player!.playURIs([NSURL(string: spotifyURI)!], withOptions: nil, callback: nil)
    }
}

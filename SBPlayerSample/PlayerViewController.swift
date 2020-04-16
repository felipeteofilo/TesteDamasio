//
//  ViewController.swift
//  TesteMobileIOS
//
//  Created by Thiago Miranda on 25/02/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import UIKit
import SambaPlayer

class PlayerViewController: UIViewController, SambaPlayerDelegate {
	
	@IBOutlet var playerContainer: UIView!
	@IBOutlet var status: UILabel!
	@IBOutlet var currentTime: UILabel!
	@IBOutlet var duration: UILabel!
	@IBOutlet var seekTo: UITextField!
	@IBOutlet var seekBy: UITextField!
	@IBOutlet var rate: UITextField!
	@IBOutlet var drmControlbar: UIView!
	@IBOutlet var policy: UILabel!
	
	var mediaInfo: MediaInfo?
	
	private static let irdetoUrl = "http://sambatech.live.ott.irdeto.com/"
	
	private var sambaPlayer: SambaPlayer?
	private var valReq: ValidationRequest?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let castButton = SambaCastButton(frame: CGRect(x: CGFloat(0), y: CGFloat(0),
                                                       width: CGFloat(24), height: CGFloat(24)))
        castButton.tintColor = UIColor.black
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: castButton)
        
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		guard let m = mediaInfo else {
			print("Error: No media info found!")
			return
		}
		
		guard sambaPlayer == nil else { return }
		
		let callback = { (media: SambaMedia?) in
			guard let media = media else { return }
			
			// DRM media
			if let valReq = m.validationRequest {
				valReq.media = media as? SambaMediaConfig
				self.valReq = valReq
				
				DispatchQueue.main.async {
					self.drmControlbar.isHidden = false
					self.policy.text = self.policies[valReq.policy]
					self.drmControlbar.setNeedsDisplay()
				}
			}
			else {
				self.initPlayer(media)
			}
		}
		
		guard let ph = m.projectHash else {
			if let url = m.mediaUrl {
				let media = SambaMediaConfig()
				media.url = url
				media.backupUrls = m.backupUrls
				media.title = m.title
				media.thumb = m.thumb
				callback(media)
			}
			
			return
		}
		
		let req: SambaMediaRequest

		if let mId = m.mediaId {
			// Live/DVR (API)
			if m.isLive {
				req = SambaMediaRequest(projectHash: ph, liveChannelId: mId)
				req.apiProtocol = SambaProtocol.http
			}
			// VoD
			else {
				req = SambaMediaRequest(projectHash: ph, mediaId: mId)
                req.apiProtocol = SambaProtocol.http
			}
		}
		// Live
		else {
			req = SambaMediaRequest(
				projectHash: ph,
				isLiveAudio: m.isLiveAudio ?? false,
				streamUrl: m.mediaUrl!,
				backupUrls: m.backupUrls)
		}
		
		if let env = m.environment {
			req.environment = env
		}
		
		SambaApi().requestMedia(req, onComplete: callback) { (error, response) in
			print("Erro ao requisitar mídia:", error ?? "no error obj", response ?? "no response obj")
		}
	}
	
	private func initPlayer(_ media: SambaMedia) {
		guard let mediaInfo = mediaInfo else {
			print("No MediaInfo instance found!")
			return
		}
		
		// media URL injection
		if let url = mediaInfo.mediaUrl {
			media.url = url
			media.outputs?.removeAll()
		}
		
		// ad injection
		if let url = mediaInfo.mediaAd {
			media.adUrl = url
			//media.adsSettings.maxRedirects = 0
			//media.adsSettings.playAdsAfterTime = 5
		}
        
        let mediaConfig = media as! SambaMediaConfig
        
        if  mediaConfig.drmRequest != nil {
            mediaConfig.drmRequest?.token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjdlN2Q5YmE4LWUzNzctNGFkMi1iZGIzLTdmOWRiOWYzZGI2ZiJ9.eyJzdWIiOiJyZWNvcmQtdXNlciIsImlzcyI6ImRpZWdvLmR1YXJ0ZUBzYW1iYXRlY2guY29tLmJyIiwianRpIjoiSUhHOUpmTVpQWkhLb0x4c28wWG95LUFkbzdtOHNaQ2Y1bk5VZ1Z4WFZJOD0iLCJleHAiOjE1NDIyMTI5NjIsImlhdCI6MTU0MTYwODE2MiwiYWlkIjoicmVjb3JkIn0.4hNHhyfnLxuWf08Neb4pSGB_5KRrU7qld2AzGthPa1Y"
        }

		configUI(media)
		
		let player = SambaPlayer(parentViewController: self, andParentView: playerContainer)
        player.isChromecastEnable = true
		player.delegate = self
        
        if media.isAudio {
            media.externalThumbURL = "http://img-sambatech.akamaized.net/unsafe/x480/gbbrpvbps-sambavideos.akamaized.net/account/3170/18/2018-08-09/thumbnail/3a249ef02e0b21e41daf98645f1e2aa8/3a249ef02e0b21e41daf98645f1e2aa8_853x480.jpg"
        }
        
        
		player.media = media
        
//        SambaCast.sharedInstance.loadMedia(with: media, currentTime: 0, captionTheme: nil, completion: { (completionType, error) in
//
//            print("complete")
//        })
		
		if mediaInfo.isAutoStart {
			player.play()
		}
		
		sambaPlayer = player
	}
	
	private func configUI(_ media: SambaMedia) {
//        if media.isAudio {
//            var frame = playerContainer.frame
//            frame.size.height = media.isLive ? 100 : 50
//            playerContainer.frame = frame
//        }
	}
	
	func onLoad() {
		if let time = sambaPlayer?.duration {
			duration.text = secondsToHoursMinutesSeconds(time)
		}
		
		status.text = "load"
	}
	
	func onStart() {
		status.text = "start"
	}
	
	func onResume() {
		status.text = "resume"
	}
	
	func onPause() {
		status.text = "pause"
	}
	
	func onProgress() {
		if let time = sambaPlayer?.currentTime {
			currentTime.text = secondsToHoursMinutesSeconds(time)
		}
		
		status.text = "progress"
	}
	
	func onFinish() {
		status.text = "finish"
	}
	
	func onDestroy() {
        status.text = "destroy"
    }
	
	func onError(_ error: SambaPlayerError) {
		status.text = "\(error.code) (\(error.cause?.code ?? -1)): \(error.cause?.localizedDescription ?? error.localizedDescription)"
		print(status.text!)
	}
	
	//MARK: actions
	
	@IBAction func playHandler() {
//        sambaPlayer?.play()
        
        let req = SambaMediaRequest(projectHash: "964b56b4b184c2a29e3c2065a7a15038", mediaId: "935283d109b33a4f92e8762d64d47661")
        
        SambaApi().requestMedia(req, onComplete: { (media: SambaMedia?) in
            guard let m = media else { return }
            
            self.configUI(m)
            self.sambaPlayer?.destroy()
            
            
            self.sambaPlayer?.media = m
            self.sambaPlayer?.play()
            
           
        }, onError: { (error, response) in
         
        })
	}
	
	@IBAction func pauseHandler() {
        sambaPlayer?.pause()
	}
	
	@IBAction func stopHandler() {
		sambaPlayer?.stop()
	}
	
	@IBAction func fullscreenHandler() {
		sambaPlayer?.fullscreen = true
	}
	
	@IBAction func controlbarHandler() {
		guard let player = sambaPlayer else { return }
		player.controlsVisible = !player.controlsVisible
	}
	
	@IBAction func swapHandler(_ sender: UIButton) {
		sender.isHidden = false
		sender.setNeedsDisplay()
        
//        MediaInfo mediaInfo3 = new MediaInfo();
//
//        mediaInfo3.setTitle("Teste Video Sem Bloqueio");
//        mediaInfo3.setProjectHash("13a157b86aa27510d0c373e447dab6ea");
//        mediaInfo3.setId("19310f3fcb5f515d1a44d5e709695c03");
//        mediaInfo3.setEnvironment(SambaMediaRequest.Environment.PROD);
//        mediaInfo3.setControlsEnabled(true);
//        mediaInfo3.setAutoPlay(true);
		
		// live: "http://liveabr2.sambatech.com.br/abr/sbtabr_8fcdc5f0f8df8d4de56b22a2c6660470/livestreamabrsbtbkp.m3u8"
		let req = SambaMediaRequest(projectHash: "13a157b86aa27510d0c373e447dab6ea", mediaId: "19310f3fcb5f515d1a44d5e709695c03")
		
		SambaApi().requestMedia(req, onComplete: { (media: SambaMedia?) in
			guard let m = media else { return }
			
			self.configUI(m)
			self.sambaPlayer?.media = m
			self.sambaPlayer?.play()
			
			sender.isHidden = false
			sender.setNeedsDisplay()
		}, onError: { (error, response) in
			sender.isHidden = false
			sender.setNeedsDisplay()
		})
	}
	
	@IBAction func createSessionHandler() {
		guard let valReq = valReq,
			let drm = valReq.media?.drmRequest else {
			print("No validation request to create session for DRM media.")
			return
		}
		
		status.text = "Creating session..."
		
		//var req = URLRequest(url: URL(string: "\(PlayerViewController.irdetoUrl)services/CreateSession?CrmId=sambatech&UserId=feijao&CreateUser=true")!)
		var req = URLRequest(url: URL(string: "\(PlayerViewController.irdetoUrl)services/CreateSession?CrmId=sambatech&UserId=samba&CreateUser=true")!)
		req.httpMethod = "POST"
		req.addValue("app@sambatech.com", forHTTPHeaderField: "MAN-user-id")
		req.addValue("c5kU6DCTmomi9fU", forHTTPHeaderField: "MAN-user-password")
		
		let xmlToDrmDelegate: XmlToDrmDelegate = XmlToDrmDelegate() { (sessionId: String, ticket: String) in
			drm.addLicenseParam(key: "SessionId", value: sessionId)
			drm.addLicenseParam(key: "Ticket", value: ticket)
			
			DispatchQueue.main.async {
				self.status.text = "Session created: \(sessionId)"
			}
		}
		
		Helpers.requestURL(req) { (response: Data?) in
			guard let data = response else { return }
			
			let xml = XMLParser(data: data)
			xml.delegate = xmlToDrmDelegate
			xml.parse()
		}
	}
	
	private let policies = [
		"Aluguel 48h (p5)",
		"Ass. mensal (p6)",
		"Aluguel 48h/BR (p7)",
		"Ass. mensal/BR (p8)"
	]
    
    @IBAction func changeControlls(_ sender: UIButton) {
        let alert = UIAlertController.init(title: "Remover Controles", message: nil, preferredStyle: .actionSheet)
        var actions:[UIAlertAction] = []
        let closure = { (control: SambaPlayerControls) in { (action: UIAlertAction!) -> Void in
                self.sambaPlayer?.hide(control)
            }
        }
        let enumOptions:[(type: SambaPlayerControls, description: String)] = [(.play, "Play Button"),
                                                                              (.playLarge, "Play Button Large"),
                                                                              (.fullscreen, "Fullscreen Button"),
                                                                              (.seekbar, "Seekbar"),
                                                                              (.topBar, "Top Bar"),
                                                                              (.bottomBar, "Bottom Bar"),
                                                                              (.time, "Time"),
                                                                              (.menu, "Menu Button"),
                                                                              (.liveIcon, "Live Icon")]
        for (_, item) in enumOptions.enumerated() {
            let action = UIAlertAction.init(title: item.description, style: .default, handler: closure(item.type))
            actions.append(action)
        }
        let action1 = UIAlertAction.init(title: "PlayLarge, FullScreen, Menu", style: .default, handler: { _ in
            self.sambaPlayer?.hide([.playLarge, .fullscreen, .menu])
        })
        actions.append(action1)
        let action2 = UIAlertAction.init(title: "TopBar, BottomBar", style: .default, handler: { _ in
            self.sambaPlayer?.hide([.topBar, .bottomBar])
        })
        actions.append(action2)
        let cancel = UIAlertAction.init(title: "Cancelar", style: .cancel, handler: { (alertAction: UIAlertAction!) in
            alert.dismiss(animated: true, completion: nil)
        })
        cancel.setValue(UIColor.red, forKey: "titleTextColor")
        for action in actions {
            alert.addAction(action)
        }
        alert.addAction(cancel)
        alert.dismiss(animated: false, completion: nil)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.permittedArrowDirections = []
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        }
        self.present(alert, animated: true, completion: nil)
    }
	
	@IBAction func policyHandler(_ sender: UIButton) {
		guard let valReq = valReq else { return }
		
		let menu = UIAlertController(title: "Policies", message: "Choose a policy to authorize/deauthorize.", preferredStyle: .actionSheet)
		let getCallback = { (index: Int) in
			return { (action: UIAlertAction) in
				valReq.policy = index
				self.policy.text = self.policies[index]
			}
		}
		
		for (i, policy) in policies.enumerated() {
			menu.addAction(UIAlertAction(title: policy, style: .default, handler: getCallback(i)))
		}
		
		menu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		menu.popoverPresentationController?.sourceView = sender
		menu.popoverPresentationController?.sourceRect = sender.bounds
		
		present(menu, animated: true, completion: nil)
	}
	
	@IBAction func outputHandler(_ sender: UIButton) {
		guard let player = sambaPlayer else { return }
		
		let outputs = player.outputs
		
		guard outputs.count > 1 else { return }
		
		let menu = UIAlertController(title: "Quality", message: "Choose an outputs to switch quality.", preferredStyle: .actionSheet)
		let getCallback = { (index: Int) in
			return { (action: UIAlertAction) in
				player.switchOutput(index)
			}
		}
		
		menu.addAction(UIAlertAction(title: "Auto", style: .default, handler: getCallback(-1)))
		
		for (i, output) in outputs.enumerated() {
			menu.addAction(UIAlertAction(title: output.label, style: .default, handler: getCallback(i)))
		}
		
		menu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		menu.popoverPresentationController?.sourceView = sender
		menu.popoverPresentationController?.sourceRect = sender.bounds
		
		present(menu, animated: true, completion: nil)
	}
	
	@IBAction func authorizeHandler(_ sender: AnyObject) {
		guard let valReq = valReq,
			let media = valReq.media,
			let drm = media.drmRequest,
			let sessionId = drm.getLicenseParam(key: "SessionId"),
			let ticket = drm.getLicenseParam(key: "Ticket") else {
			print("No validation request or session created to authorize DRM media.")
			return
		}
		
		let deauth = (sender as? UIView)?.tag == 1
		let params: String
		
		switch valReq.policy {
		case 0: params = "&OptionId=6&ContentId=\(media.id)"
		case 1: params = "&PackageId=2"
		case 2: params = "&OptionId=7&ContentId=\(media.id)"
		case 3: params = "&PackageId=3"
		default: params = ""
		}
		
		status.text = deauth ? "Deauthorizing..." : "Authorizing..."
		
		let url = "\(PlayerViewController.irdetoUrl)services/\(deauth ? "Deauthorize" : "Authorize")?CrmId=sambatech&AccountId=sambatech" +
			"&SessionId=\(sessionId)&Ticket=\(ticket)&UserIp=\(AppDelegate.externalIp)\(params)"
		var req = URLRequest(url: URL(string: url)!)
		
		req.httpMethod = "POST"
		req.addValue("app@sambatech.com", forHTTPHeaderField: "MAN-user-id")
		req.addValue("c5kU6DCTmomi9fU", forHTTPHeaderField: "MAN-user-password")
		
		Helpers.requestURL(req) { (response: String?) in
			DispatchQueue.main.async {
				self.status.text = "\(deauth ? "Deauthorized" : "Authorized"): \(valReq.policy < self.policies.count ? self.policies[valReq.policy] : "unknown")"
			}
		}
	}
	
	@IBAction func loadHandler() {
		guard let media = valReq?.media else {
			print("Invalid DRM media request.")
			return
		}
		
		status.text = "Loading..."
		
		initPlayer(media)
	}
	
	@IBAction func seekHandler() {
		guard let posStr = seekTo.text,
			let pos = Float(posStr) else { return }
		sambaPlayer?.seek(pos)
	}
	
	@IBAction func rwHandler() {
		guard let byStr = seekBy.text,
			let time = sambaPlayer?.currentTime,
			let by = Float(byStr) else { return }
		sambaPlayer?.seek(time - by)
	}
	
	@IBAction func fwHandler() {
		guard let byStr = seekBy.text,
			let time = sambaPlayer?.currentTime,
			let by = Float(byStr) else { return }
		sambaPlayer?.seek(time + by)
	}
	
	@IBAction func rateHandler() {
		guard let rateStr = self.rate.text,
			let rate = Float(rateStr) else { return }
		sambaPlayer?.rate = rate
	}
	
	//MARK: utils
	
	private func secondsToHoursMinutesSeconds(_ seconds : Float) -> (String) {
		let s = Int(seconds)
		return String(format: "%02d:%02d:%02d", s/3600%60, s/60%60, s%60)
	}
    
    deinit {
        print("deinit")
    }
}

class XmlToDrmDelegate : NSObject, XMLParserDelegate {
	
	let callback: (_: String, _: String) -> Void

	init(callback: @escaping (_: String, _: String) -> Void) {
		self.callback = callback
	}
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
		guard elementName == "Session",
			let sessionId = attributeDict["SessionId"],
			let ticket = attributeDict["Ticket"]
			else { return }
		
		callback(sessionId, ticket)
	}
}

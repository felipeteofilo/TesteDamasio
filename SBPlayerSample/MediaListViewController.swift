//
//  MediaListViewControlller.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/3/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import AVKit
import SambaPlayer

class MediaListViewController : UITableViewController {
	
	var categoryInfo: CategoryInfo?
	
	private var mediaList = [MediaInfo]()
	private var mediaListFiltered = [MediaInfo]()
	private let envs: [SambaEnvironment] = [.prod, .staging, .test]
	private let envNames = ["All", "Prod", "Staging", "Test"]
	private var currentFilterIndex = -1
	
	@IBAction func envButtonHandler(_ sender: UIBarButtonItem) {
		let menu = UIAlertController(title: "Environment", message: "Choose a filter", preferredStyle: .actionSheet)
		
		let getCallback = { (index: Int) in
			return { (action: UIAlertAction) in
				DispatchQueue.main.async {
					self.filterData(index, withBarButton: sender)
					self.tableView.reloadData()
				}
			}
		}
		
		menu.addAction(UIAlertAction(title: envNames[0], style: .default, handler: getCallback(-1)))
		
		for (i, _) in envs.enumerated() {
			menu.addAction(UIAlertAction(title: envNames[i + 1], style: .default, handler: getCallback(i)))
		}
		
		menu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		
		if let view = sender.value(forKey: "view") as? UIView {
			menu.popoverPresentationController?.sourceView = view
			menu.popoverPresentationController?.sourceRect = view.bounds
		}
		
		present(menu, animated: true, completion: nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.backgroundColor = UIColor.clear
		
		// refresh control
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(refreshRequestedHandler), for: .valueChanged)
		refreshControl.tintColor = UIColor(0xCCCCCC)
		self.refreshControl = refreshControl
		
        let castButton = SambaCastButton(frame: CGRect(x: CGFloat(0), y: CGFloat(0),
                                                        width: CGFloat(24), height: CGFloat(24)))
        castButton.tintColor = .black
        
        let offlineButton = UIBarButtonItem(title: "OFFLINE", style: .plain, target: self, action: #selector(onOfflineClick))
        
        offlineButton.tintColor = .black
        
        self.navigationItem.rightBarButtonItems = [offlineButton, UIBarButtonItem(customView: castButton)]
        
        
        SambaCast.sharedInstance.presentCastInstruction(with: castButton)
        
		makeInitialRequests()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "MediaToPlayer",
			let index = (tableView.indexPathForSelectedRow as NSIndexPath?)?.row,
			index < mediaListFiltered.count
		else { return }
		
		(segue.destination as! PlayerViewController).mediaInfo = mediaListFiltered[index]
	}
	
	override func tableView(_ tableView: UITableView?, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "MediaCell"
		let cell = tableView!.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! MediaCell
		let media = mediaListFiltered[(indexPath as NSIndexPath).row]
		let odd = (indexPath as NSIndexPath).row & 1 == 0
		
		cell.mediaTitle.text = media.title
        cell.mediaDesc.text = media.description ?? ""
		media.imageView = cell.mediaThumb
		
		switch media.environment ?? .prod {
		case .prod: cell.contentView.backgroundColor = UIColor(odd ? 0xeeffee : 0xddffdd)
		case .staging: cell.contentView.backgroundColor = UIColor(odd ? 0xddeeff : 0xccddff)
		case .test: cell.contentView.backgroundColor = UIColor(odd ? 0xffeeee : 0xffdddd)
		default: cell.contentView.backgroundColor = UIColor(odd ? 0xeeeeee : 0xffffff)
		}
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return mediaListFiltered.count
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.tableView.deselectRow(at: indexPath, animated: false)
//        playerController
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let playlistDetailViewController = storyBoard.instantiateViewController(withIdentifier: "playerController") as! PlayerViewController
        playlistDetailViewController.mediaInfo =  mediaListFiltered[indexPath.row]
        self.navigationController?.pushViewController(playlistDetailViewController, animated: true)

	}
	
	private func makeInitialRequests() {
//        Helpers.requestURLJson("http://playerground.sambatech.com/v1/liquid/medias?cat_id=16") { json in
//            guard let json = json as? [AnyObject] else {
//                // hides fetching data info
//                self.refreshControl?.endRefreshing()
//                return
//            }
//
//            for jsonNode in json {
//                var isAudio = false
//                var env = SambaEnvironment.prod
//                let params = jsonNode["params"] as AnyObject
//                var backupUrls = [String]()
//
//                // skip non video or audio media
//                switch (jsonNode["qualifier"] as? String ?? "").lowercased() {
//                case "audio": isAudio = true
//                default: break
//                }
//
//                switch (jsonNode["env"] as? String ?? "").lowercased() {
//                case "prod": env = .prod
//                case "staging": env = .staging
//                case "dev": fallthrough
//                case "web1-13000": env = .test
//                default: break
//                }
//
//                if let backupUrl = params["backupLive"] as? String {
//                    backupUrls.append(backupUrl)
//                }
//
//                let m = MediaInfo(
//                    title: jsonNode["title"] as? String ?? "Unknown",
//                    description: jsonNode["description"] as? String,
//                    thumb: isAudio ? "https://cdn4.iconfinder.com/data/icons/defaulticon/icons/png/256x256/media-volume-2.png" : jsonNode["thumbnail"] as? String,
//                    projectHash: jsonNode["ph"] as? String,
//                    // tries to get VOD or Live ID
//                    mediaId: jsonNode["id"] as? String ?? jsonNode["liveChannelId"] as? String,
//                    mediaAd: params["ad_program"] as? String,
//                    // WORKAROUND: to identify which project has DRM
//                    validationRequest: (jsonNode["drm"] as? Bool ?? false) ? ValidationRequest() : nil,
//                    isLive: jsonNode["liveChannelId"]! != nil,
//                    isAudio: isAudio,
//                    env: env,
//                    mediaUrl: params["primaryLive"] as? String,
//                    backupUrls)
//
//                self.mediaList.append(m)
//            }
//
//            self.filterData(self.currentFilterIndex)
//
//            DispatchQueue.main.async {
//                self.tableView.reloadData()
//                // hides fetching data info
//                self.refreshControl?.endRefreshing()
//            }
//        }
        
        self.mediaList.append(MediaInfo(
            title: "Teste Audio lento",
            projectHash: "4f25046e52b1b4643efd8a328b78fbf3",
            mediaId: "bc6e1ec855f8f1142232f4282bfe5ed9",
            mediaAd: nil,
            validationRequest: nil,
            isLive: false))
        
        self.mediaList.append(MediaInfo(
            title: "Media Playplus",
            projectHash: "fad2b4a201ef2305d06cb817da1bd262",
            mediaId: "ca60065f62e83445a4c5ae91abd3eacf",
            mediaAd: nil,
            validationRequest: nil,
            isLive: false))
        
        self.mediaList.append(MediaInfo(
            title: "Teste Live Playplus ESPN",
            projectHash: "548fd94beda15ebe2fa22adf1839b60c",
            mediaId: "3958f83a366a90dbbd093f8907129171",
            mediaAd: nil,
            validationRequest: nil,
            isLive: true))
        
        self.mediaList.append(MediaInfo(
            title: "Teste Media Legenda",
            projectHash: "964b56b4b184c2a29e3c2065a7a15038",
            mediaId: "935283d109b33a4f92e8762d64d47661"))
        
//        self.mediaList.append(MediaInfo(
//            title: "Live Teste Analytics",
//            projectHash: "964b56b4b184c2a29e3c2065a7a15038",
//            mediaId: "46fe05239a330e011ea2d0f36b1f0702",
//            mediaAd: nil,
//            validationRequest: nil,
//            isLive: true))


        
        self.mediaList.append(MediaInfo(
            title: "Media DRM",
            projectHash: "ffd0b8a31839f239ae6b8b3c83eb10a2",
            mediaId: "a1ed670cbb7f65402a685c19f808ca16",
            mediaAd: nil,
            validationRequest: nil,
            isLive: false, env: SambaEnvironment.staging))
        
        DispatchQueue.main.async {
            self.filterData(-1)
            self.tableView.reloadData()
            // hides fetching data info
            self.refreshControl?.endRefreshing()
        }
	}
	
	private func filterData(_ index: Int, withBarButton barButton: UIBarButtonItem? = nil) {
		currentFilterIndex = index
		
		// filtered
		if index > -1 {
			self.mediaListFiltered = self.mediaList.filter({$0.environment == self.envs[index]})
		}
		// all
		else {
			self.mediaListFiltered = self.mediaList
		}
		
		barButton?.title = self.envNames[index + 1]
	}
	
	@objc private func refreshRequestedHandler() {
		mediaList = [MediaInfo]()
		makeInitialRequests()
	}
    
    @objc func onOfflineClick() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let offlineViewController = storyBoard.instantiateViewController(withIdentifier: "offline") as! OfflineViewController
         self.navigationController?.pushViewController(offlineViewController, animated: true)
    }
    
}

class MediaInfo {
	
	let title: String
	let projectHash: String?
	let mediaId: String?
	var mediaAd: String?
	var description: String?
	let isLive: Bool
	let isAudio: Bool
	let isLiveAudio: Bool?
	var isAutoStart = true
	var validationRequest: ValidationRequest?
	var environment: SambaEnvironment?
	var mediaUrl: String?
	var backupUrls: [String]
    var drmToken: String?
	
	var thumb: UIImage? {
		didSet {
			if let imageView = imageView {
				self.imageView = imageView
			}
		}
	}
	
	var imageView: UIImageView? {
		didSet {
			guard let imageView = imageView else { return }
			
			if let thumb = thumb {
				DispatchQueue.main.async {
					imageView.image = thumb
				}
			}
		}
	}
	
	init(title: String, description: String? = nil, thumb: String? = nil, projectHash: String? = nil, mediaId: String? = nil,
	     mediaAd: String? = nil, validationRequest: ValidationRequest? = nil, isLive: Bool = false, isAudio: Bool = false,
         isLiveAudio: Bool? = false, env: SambaEnvironment? = nil, mediaUrl: String? = nil, _ backupUrls: [String]? = nil, drmToken: String? = nil) {
		self.title = title
		self.description = description
		self.projectHash = projectHash
		self.mediaId = mediaId
		self.validationRequest = validationRequest
		self.mediaAd = mediaAd
		self.isLive = isLive
		self.isAudio = isAudio
		self.isLiveAudio = isLiveAudio
		self.environment = env
		self.mediaUrl = mediaUrl
		self.backupUrls = backupUrls ?? [String]()
        self.drmToken = drmToken
		
		load_image(thumb)
	}
	
	private func load_image(_ url: String?) {
		guard let url = url else { return }
		
		Helpers.requestURL(url) { (data: Data?) in
			if let data = data,
				let img = UIImage(data: data) {
				self.thumb = img
			}
		}
	}
}

class ValidationRequest {
	let contentId: String?
	var media: SambaMediaConfig?
	var policy: Int = 0
	
	init(contentId: String? = nil) {
		self.contentId = contentId
	}
	
	convenience init(contentId: String? = nil, policy: Int) {
		self.init(contentId: contentId)
		self.policy = policy
	}
}

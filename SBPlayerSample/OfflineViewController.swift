//
//  OfflineViewController.swift
//  Player-swift
//
//  Created by Kesley Vaz on 28/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import UIKit
import SambaPlayer

class OfflineViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let TOKEN_DRM = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImY5NTRiMTIzLTI1YzctNDdmYy05MmRjLThkODY1OWVkNmYwMCJ9.eyJzdWIiOiJkYW1hc2lvLXVzZXIiLCJpc3MiOiJkaWVnby5kdWFydGVAc2FtYmF0ZWNoLmNvbS5iciIsImp0aSI6IklIRzlKZk1aUFpIS29MeHNvMFhveS1BZG83bThzWkNmNW5OVWdWeFhWSTg9IiwiZXhwIjoxNTg5NTc3NDI4LCJpYXQiOjE1ODY5ODU0MjgsImFpZCI6ImRhbWFzaW8ifQ.A9FuSqiVom5Y2b2BIjPPeK-SJf_m38DjL41AWh3DFV0"
    
    
    @IBOutlet weak var containerPlayerView: UIView!
    
    @IBOutlet weak var mediasTableView: UITableView!
    
    @IBOutlet weak var progressContainer: UIView!
    
    @IBOutlet weak var progressView: UIActivityIndicatorView!
    
    var mediaList: [MediaInfo] = []
    
    var sambaPlayer: SambaPlayer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let menuButton = UIBarButtonItem(title: "MENU", style: .plain, target: self, action: #selector(envButtonHandler))
        
        menuButton.tintColor = .black
        
        self.navigationItem.rightBarButtonItem = menuButton
        
        self.mediasTableView.tableFooterView = UIView(frame: CGRect.zero)
        sambaPlayer = SambaPlayer(parentViewController: self, andParentView: containerPlayerView)
        sambaPlayer?.delegate = self
        
        mediaList.append(MediaInfo(
            title: "Media DRM 1",
            projectHash: "594f9628bf8b04836021f45c9a63d071",
            mediaId: "eda5ae29ebc4138ae905fe9b0d36bd0d",
            mediaAd: nil,
            validationRequest: nil,
            isLive: false,
            drmToken: TOKEN_DRM
        ))
        
        mediasTableView.reloadData()
        
    }
    
    //MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "mediaCellOffline") as! MediaOfflineCell
        
        cell.media = mediaList[indexPath.row]
        
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let mediaInfo = mediaList[indexPath.row]
        
        if let offlineMedia = SambaDownloadManager.sharedInstance.getDownloadedMedia(for: mediaInfo.mediaId!) {
            
            let mediaConfig = offlineMedia as! SambaMediaConfig
            
            if mediaConfig.drmRequest != nil {
                mediaConfig.drmRequest?.token = mediaInfo.drmToken
            }
            
            SambaApi().prepareOfflineMedia(media: mediaConfig, onComplete: { [weak self] (sambaMedia) in
                
                guard let strongSelf = self else {return}
                strongSelf.sambaPlayer?.destroy()
                strongSelf.sambaPlayer?.media = sambaMedia!
                strongSelf.sambaPlayer?.play()
                
            }) { [weak self] (error, response) in
                guard let strongSelf = self else {return}
                strongSelf.showErrorDialog("Erro ao carregar a media.")
            }
            
        } else {
            SambaApi().requestMedia(SambaMediaRequest(projectHash: mediaInfo.projectHash!, mediaId: mediaInfo.mediaId!), onComplete: { [weak self] (sambaMedia) in
                
                guard let strongSelf = self else {return}
                
                if let sambaConfig = sambaMedia as? SambaMediaConfig, let drmRequest = sambaConfig.drmRequest {
                    drmRequest.token = mediaInfo.drmToken
                }
                
                strongSelf.sambaPlayer?.destroy()
                strongSelf.sambaPlayer?.media = sambaMedia!
                strongSelf.sambaPlayer?.play()
                
            }) { [weak self] (error, response) in
                guard let strongSelf = self else {return}
                strongSelf.showErrorDialog("Erro ao carregar a media.")
            }
        }
        
    }
    
    func showErrorDialog(_ error: String) {
        
        let alert = UIAlertController(title: "Atenção", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func enableProgress(_ enable: Bool) {
        
        if enable {
            progressContainer.isHidden = false
            progressView.startAnimating()
        } else {
            progressContainer.isHidden = true
            progressView.stopAnimating()
        }
        
    }
    
    func buildResolutionsDialog(with request: SambaDownloadRequest, onClick: @escaping (_ sambaTrack: SambaTrack) -> Void) {
        let alert = UIAlertController(title: "Download Media", message: "Escolha a resolução desejada.", preferredStyle: .alert)
        
        var tracks: [SambaTrack] = []
        
        tracks.append(contentsOf: request.sambaVideoTracks ?? [] as! [SambaTrack])
        tracks.append(contentsOf: request.sambaAudioTracks ?? [] as! [SambaTrack])
        
        tracks.forEach { (item) in
            alert.addAction(UIAlertAction(title: String(format: "\(item.title) - %.0f MB", item.sizeInMb), style: .default, handler: { (action) in
                onClick(item)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .destructive, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func buildOptionDialog(_ msg: String, _ onClick: @escaping () -> ()) {
        let alert = UIAlertController(title: "Download Media", message: msg, preferredStyle: .alert)


        alert.addAction(UIAlertAction(title: "ok", style: .default, handler: { (action) in
                onClick()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .destructive, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func envButtonHandler(_ sender: UIBarButtonItem) {
        let menu = UIAlertController(title: "Menu", message: "Selecione a opção desejada", preferredStyle: .actionSheet)
    
        menu.addAction(UIAlertAction(title: "Cancelar Todos Downloads", style: .default, handler: { action in
            SambaDownloadManager.sharedInstance.cancelAllDownloads()
        }))
        
        menu.addAction(UIAlertAction(title: "Pausar Todos Downloads", style: .default, handler: { action in
            SambaDownloadManager.sharedInstance.pauseAllDownloads()
        }))
        
        menu.addAction(UIAlertAction(title: "Retornar Todos Downloads Pausados", style: .default, handler: { action in
            SambaDownloadManager.sharedInstance.resumeAllDownloads()
        }))
        
        menu.addAction(UIAlertAction(title: "Deletar Todos Downloads", style: .default, handler: { action in
            SambaDownloadManager.sharedInstance.deleteAllMedias()
        }))
        
        menu.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        
        if let view = sender.value(forKey: "view") as? UIView {
            menu.popoverPresentationController?.sourceView = view
            menu.popoverPresentationController?.sourceRect = view.bounds
        }
        
        present(menu, animated: true, completion: nil)
    }

}


extension OfflineViewController: SambaPlayerDelegate {
    
    func onLoad() {
        
    }
    
    func onPause() {
        
    }
    
    func onFinish() {
        
    }
    
}

extension OfflineViewController: DownloadClickDelegate {
    
    func onDownloadClick(with mediaInfo: MediaInfo) {
        
        
        guard !SambaDownloadManager.sharedInstance.isPaused(mediaInfo.mediaId!) else {
            SambaDownloadManager.sharedInstance.resumeDownload(for: mediaInfo.mediaId!)
            return
        }
        
        guard !SambaDownloadManager.sharedInstance.isDownloaded(mediaInfo.mediaId!) else {
            buildOptionDialog("Deseja apagar a media \(mediaInfo.title)?") {
                SambaDownloadManager.sharedInstance.deleteMedia(for: mediaInfo.mediaId!)
            }
            return
        }
        
        guard !SambaDownloadManager.sharedInstance.isDownloading(mediaInfo.mediaId!) else {
            
            let alert = UIAlertController(title: "Download Media", message: "O que deseja fazer?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Pausar Download", style: .default, handler: { (action) in
                SambaDownloadManager.sharedInstance.pauseDownload(for: mediaInfo.mediaId!)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancelar Download", style: .default, handler: { (action) in
                SambaDownloadManager.sharedInstance.cancelDownload(for: mediaInfo.mediaId!)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancelar", style: .destructive, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        enableProgress(true)
        
        let request = SambaDownloadRequest(mediaId: mediaInfo.mediaId!, projectHash: mediaInfo.projectHash!)

        if let token = mediaInfo.drmToken, !token.isEmpty {

            request.drmToken = token

        }
    
        SambaDownloadManager.sharedInstance.prepareDownload(with: request, successCallback: { [weak self](sambaDownloadRequest) in
            guard let strongSelf = self else {return}
            
            strongSelf.enableProgress(false)
            strongSelf.buildResolutionsDialog(with: request, onClick: { (sambaTrack) in
                
                request.sambaTrackForDownload = sambaTrack
                
                if let subtitles = request.sambaSubtitles, !subtitles.isEmpty {
                     request.sambaSubtitleForDownload = subtitles[0]
                }
                
                SambaDownloadManager.sharedInstance.performDownload(with: request)
            })
            
        }) { [weak self] (error, msg) in
            guard let strongSelf = self else {return}
            strongSelf.enableProgress(false)
            strongSelf.showErrorDialog("Error ao preparar o Download.")
        }
    
        
    }
    
}

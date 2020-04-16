//
//  MediaOfflineCellTableViewCell.swift
//  Player-swift
//
//  Created by Kesley Vaz on 28/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import UIKit
import SambaPlayer

class MediaOfflineCell: UITableViewCell {
    
    @IBOutlet weak var mediaTitleLabel: UILabel!
    
    @IBOutlet weak var progressContainer: UIView!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var indeterminateProgress: UIActivityIndicatorView!
    
    @IBOutlet weak var downloadButton: UIButton!
    
    
    weak var delegate: DownloadClickDelegate?
    
    var media: MediaInfo? {
        didSet {
            mediaTitleLabel.text = media?.title
            
            NotificationCenter.default.addObserver(self,
                                           selector: #selector(handlerDownloadState(_:)),
                                           name: .SambaDownloadStateChanged, object: nil)
            
            updateViews()
           
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let progresstap = UITapGestureRecognizer(target: self, action: #selector(progressContainerClick))
        self.progressContainer.addGestureRecognizer(progresstap)
        
    }
    
    
    func updateViews()  {
        
        if SambaDownloadManager.sharedInstance.isPaused((media?.mediaId)!) {
            downloadButton.isHidden = false
            downloadButton.setImage(UIImage(named: "pause"), for: .normal)
            
        } else if SambaDownloadManager.sharedInstance.isDownloaded((media?.mediaId)!) {
            downloadButton.isHidden = false
            downloadButton.setImage(UIImage(named: "downloadDone"), for: .normal)
            
        } else if SambaDownloadManager.sharedInstance.isDownloading((media?.mediaId)!) {
            
            downloadButton.isHidden = true
            downloadButton.setImage(UIImage(named: "download"), for: .normal)
        } else {
            downloadButton.isHidden = false
            downloadButton.setImage(UIImage(named: "download"), for: .normal)
        }
    }
    
    func updateProgress(_ downloadState: DownloadState)  {
       
        switch downloadState.state {
            case DownloadState.State.WAITING, DownloadState.State.RESUMED:
                downloadButton.isHidden = true
                progressView.isHidden = true
                progressLabel.isHidden = true
                indeterminateProgress.isHidden = false
                indeterminateProgress.startAnimating()
            case DownloadState.State.IN_PROGRESS:
                downloadButton.isHidden = true
                progressView.isHidden = false
                progressLabel.isHidden = false
                indeterminateProgress.stopAnimating()
                indeterminateProgress.isHidden = true
            
                let percentage = downloadState.downloadPercentage >= 0 ? downloadState.downloadPercentage: 0
                progressView.setProgress(percentage, animated: true)
                progressLabel.text = String(format: "%.1f%%", percentage * 100)
            
           case DownloadState.State.COMPLETED:
                downloadButton.isHidden = false
                progressView.isHidden = true
                progressLabel.isHidden = true
                indeterminateProgress.stopAnimating()
                indeterminateProgress.isHidden = true
            default:
                downloadButton.isHidden = false
                progressView.isHidden = true
                progressLabel.isHidden = true
                indeterminateProgress.stopAnimating()
                indeterminateProgress.isHidden = true
        }
    }
    
    @IBAction func downloadButtonClicked(_ sender: Any) {
        delegate?.onDownloadClick(with: media!)
    }
    
    @objc func progressContainerClick() {
        delegate?.onDownloadClick(with: media!)
    }
    
    @objc func handlerDownloadState(_ notification: Notification) {
        guard let downloadState = DownloadState.from(notification: notification), downloadState.downloadData.mediaId == media?.mediaId else {
            return
        }
        
        updateViews()
        
        updateProgress(downloadState)
        
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}


protocol DownloadClickDelegate: class {
    func onDownloadClick(with mediaInfo: MediaInfo)
}

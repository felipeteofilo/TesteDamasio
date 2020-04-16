//
//  MediaListCellViewControllerTableViewCell.swift
//  TesteMobileIOS
//
//  Created by Thiago Miranda on 11/03/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import UIKit

class CategoryCell: UITableViewCell {
    
	@IBOutlet var titleLabel: UILabel!
	
    override func awakeFromNib() {
        super.awakeFromNib()
		
		layer.borderWidth = 0.5
		layer.borderColor = UIColor.green.cgColor
    }
}

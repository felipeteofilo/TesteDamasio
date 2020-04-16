//
//  MediaListViewControlller.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/3/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import AVKit
import SambaPlayer

class CategoryListViewController : UITableViewController {
	
	private var categoryList = [CategoryInfo]()
	
	override func viewDidLoad() {
		self.tableView.backgroundColor = UIColor.clear
		makeInitialRequests()
		
		// refresh control
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(refreshRequestedHandler), for: .valueChanged)
		refreshControl.tintColor = UIColor(0xCCCCCC)
		self.refreshControl = refreshControl
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "CategoryToMediaList",
			let index = (tableView.indexPathForSelectedRow as NSIndexPath?)?.row,
			index < categoryList.count
		else { return }
		
		(segue.destination as! MediaListViewController).categoryInfo = categoryList[index]
	}
	
	override func tableView(_ tableView: UITableView?, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "CategoryCell"
		let cell = tableView!.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CategoryCell
		
		let category = categoryList[(indexPath as NSIndexPath).row]
		
		cell.titleLabel.text = category.title
		cell.contentView.backgroundColor = UIColor((indexPath as NSIndexPath).row & 1 == 0 ? 0xEEEEEE : 0xFFFFFF)
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return categoryList.count
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.tableView.deselectRow(at: indexPath, animated: false)
	}
	
	private func makeInitialRequests() {
		categoryList.append(CategoryInfo(id: 12, title: "SDK"))
		
		DispatchQueue.main.async {
			self.tableView.reloadData()
			self.refreshControl?.endRefreshing()
		}
	}
	
	@objc private func refreshRequestedHandler() {
		categoryList = [CategoryInfo]()
		makeInitialRequests()
	}
}

struct CategoryInfo {
	let id: Int, title: String
}

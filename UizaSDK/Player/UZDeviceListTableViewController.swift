//
//  UZDeviceListTableViewController.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/25/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

open class UZDeviceListTableViewController: UITableViewController {
	
	let castingManager = UZCastingManager.shared

	override open func viewDidLoad() {
        super.viewDidLoad()
		
    }
	
    // MARK: - Table view data source

    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return section == 0 ? castingManager.deviceCount : 1
    }
	
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
		
        return cell
    }
	
	override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 50
	}
	
	override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			
		}
		else {
			
		}
	}

}

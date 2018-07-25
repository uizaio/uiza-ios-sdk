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
	
	override open func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		castingManager.startDiscovering()
	}
	
	override open func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		castingManager.stopDiscovering()
	}
	
	override open var preferredContentSize: CGSize {
		get {
			var screenSize = UIScreen.main.bounds.size
			screenSize.width = min(320, screenSize.width * 0.8)
			screenSize.height = min(min(400, screenSize.height * 0.8), CGFloat((castingManager.deviceCount + 1) * 50))
			return screenSize
		}
		set {
			super.preferredContentSize = newValue
		}
	}
	
    // MARK: - Table view data source

    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return section == 0 ? castingManager.deviceCount : 1
    }
	
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
		
		if cell == nil {
			cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
		}
		
        return cell!
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

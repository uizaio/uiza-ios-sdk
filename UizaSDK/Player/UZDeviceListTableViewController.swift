//
//  UZDeviceListTableViewController.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/25/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import NKModalViewManager

open class UZDeviceListTableViewController: UITableViewController {
	
	let castingManager = UZCastingManager.shared

	override open func viewDidLoad() {
        super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self, selector: #selector(onDeviceListUpdated), name: NSNotification.Name.UZDeviceListDidUpdate, object: nil)
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
			screenSize.height = min(min(400, screenSize.height * 0.8), CGFloat((castingManager.deviceCount + 2) * 50))
			return screenSize
		}
		set {
			super.preferredContentSize = newValue
		}
	}
	
	override open func dismiss(animated flag: Bool, completion: (() -> Void)?) {
		if let viewController = NKModalViewManager.sharedInstance().modalViewControllerThatContains(self) {
			viewController.dismissWith(animated: flag, completion: completion)
		}
		else {
			super.dismiss(animated: flag, completion: completion)
		}
	}
	
    // MARK: - Table view data source

    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return section == 1 ? castingManager.deviceCount : 1
    }
	
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
		
		if cell == nil {
			cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
		}
		
        return cell!
    }
	
	override open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let normalColor = UIColor(white: 0.2, alpha: 1.0)
		let selectedColor = UIColor(red:0.28, green:0.49, blue:0.93, alpha:1.00)
		
		if indexPath.section == 0 {
			if UIDevice.isPhone() {
				cell.textLabel?.text = "This iPhone"
				cell.imageView?.image = UIImage(icon: .googleMaterialDesign(.phoneIphone), size: CGSize(width: 32, height: 32), textColor: normalColor, backgroundColor: .clear)
				cell.imageView?.highlightedImage = UIImage(icon: .googleMaterialDesign(.phoneIphone), size: CGSize(width: 32, height: 32), textColor: selectedColor, backgroundColor: .clear)
			}
			else {
				cell.textLabel?.text = "This iPad"
				cell.imageView?.image = UIImage(icon: .googleMaterialDesign(.tablet), size: CGSize(width: 32, height: 32), textColor: normalColor, backgroundColor: .clear)
				cell.imageView?.highlightedImage = UIImage(icon: .googleMaterialDesign(.tablet), size: CGSize(width: 32, height: 32), textColor: selectedColor, backgroundColor: .clear)
			}
			
			cell.detailTextLabel?.text = "Playing here"
			cell.accessoryType = castingManager.currentCastSession == nil ? .checkmark : .none
		}
		else if indexPath.section == 1 {
			let device = castingManager.device(at: UInt(indexPath.row))
			cell.textLabel?.text = device.modelName
			cell.detailTextLabel?.text = "Connect"
			cell.imageView?.image = UIImage(icon: .googleMaterialDesign(.cast), size: CGSize(width: 32, height: 32), textColor: normalColor, backgroundColor: .clear)
			cell.imageView?.highlightedImage = UIImage(icon: .googleMaterialDesign(.cast), size: CGSize(width: 32, height: 32), textColor: selectedColor, backgroundColor: .clear)
			
			if let currentCastSession = castingManager.currentCastSession {
				cell.accessoryType = currentCastSession.device == device ? .checkmark : .none
			}
			else {
				cell.accessoryType = .none
			}
		}
		else if indexPath.section == 2 {
			cell.textLabel?.text = "AirPlay and Bluetooth"
			cell.detailTextLabel?.text = "Show more devices..."
			cell.imageView?.image = UIImage(icon: .googleMaterialDesign(.airplay), size: CGSize(width: 32, height: 32), textColor: normalColor, backgroundColor: .clear)
			cell.imageView?.highlightedImage = UIImage(icon: .googleMaterialDesign(.airplay), size: CGSize(width: 32, height: 32), textColor: selectedColor, backgroundColor: .clear)
			cell.accessoryType = .none
		}
	}
	
	override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 50
	}
	
	override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			castingManager.disconnect()
			self.dismiss(animated: true, completion: nil)
		}
		else if indexPath.section == 1 {
			let device = castingManager.device(at: UInt(indexPath.row))
			castingManager.connect(to: device)
			
			if let cell = tableView.cellForRow(at: indexPath) {
				let loadingView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
				loadingView.hidesWhenStopped = true
				loadingView.startAnimating()
				cell.accessoryView = loadingView
			}
		}
		else {
			self.dismiss(animated: true) {
				PostNotification(.UZShowAirPlayDeviceList)
			}
		}
	}
	
	// MARK: -
	
	@objc func onDeviceListUpdated() {
		self.tableView.reloadData()
		self.presentingModalViewController()?.setNeedsLayoutView()
	}

}

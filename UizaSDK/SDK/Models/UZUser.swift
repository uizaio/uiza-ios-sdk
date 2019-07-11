//
//  UZUser.swift
//  UizaSDK
//
//  Created by Nam Kennic on 4/26/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit

let CURRENT_USER_KEY = "com.uiza.currentUser.3_0"

/**
Info of user
*/
open class UZUser: UZModelObject {
	/** `id` of user */
	public var id : String!
	/** Name of user */
	public var name : String?
	/** Gender of user */
	public var gender : String? // male / female
	/** Mobile phone */
	public var mobile : String?
	/** Email address */
	public var email : String?
	/** Birthday of user */
	public var birthday : Date? = nil
	/** Facebook ID, if logged in from Facebook */
	public var facebookId : String?
	/** Avatar URL */
	public var avatarURL : URL? = nil
	/** Token of user */
	public var token : String?
	
	/** `true` if this is you */
	public var isMe: Bool {
		get {
			if let currentUser = UZUser.currentUser {
				return self.id == currentUser.id
			}
			
			return false
		}
	}
	
	fileprivate static var _currentUser : UZUser? = nil
	/** Logged in user, returns `nil` if user is not logged in */
	public class var currentUser: UZUser? {
		get {
			if (_currentUser == nil) {
				let userData : Data? = UserDefaults.standard.object(forKey: CURRENT_USER_KEY) as? Data
				if (userData != nil) {
					_currentUser = NSKeyedUnarchiver.unarchiveObject(with: userData!) as? UZUser
				}
			}
			
			return _currentUser
		}
		/*
		set (newValue) {
			if (_currentUser != newValue) {
				_currentUser = newValue
				
				if _currentUser != nil {
					let userData: Data = NSKeyedArchiver.archivedData(withRootObject: _currentUser!)
					UserDefaults.standard.set(userData, forKey: CURRENT_USER_KEY)
					UserDefaults.standard.synchronize()
				}
				else {
					UserDefaults.standard.removeObject(forKey: CURRENT_USER_KEY)
					UserDefaults.standard.synchronize()
				}
			}
		}
		*/
	}
	
//	/** Token của Facebook nếu đây là người dùng được login bằng Facebook */
//	public var facebookToken : FBSDKAccessToken? {
//		didSet {
//			if facebookToken != nil {
//				data?.setValue(facebookToken, forKey:"facebookToken")
//			}
//			else {
//				data?.removeObject(forKey: "facebookToken")
//			}
//		}
//	}
//
//	/** Facebook Profile nếu đây là người dùng được login bằng Facebook */
//	public var facebookProfile : FBSDKProfile? {
//		didSet {
//			if facebookProfile != nil {
//				data?.setValue(facebookProfile, forKey:"facebookProfile")
//			}
//			else {
//				data?.removeObject(forKey: "facebookProfile")
//			}
//		}
//	}
	
	/**
	URL of Facebook avatar if user has logged in from Facebook
	- parameter size: Kích thước hình đại diện
	*/
	public func facebookAvatar(size: Int = 100) -> URL? {
		if facebookId != nil && facebookId!.count > 0 {
			let finalSize = size * Int(UIScreen.main.scale)
			let result = "https://graph.facebook.com/\(facebookId!)/picture?width=\(finalSize)"
			return URL(string: result)
		}
		
		return nil
	}
	
	
	// MARK: -
	
	internal func saveAsCurrentUser() {
		UZUser._currentUser = self;
//		self.facebookToken = FBSDKAccessToken.current()
		
		let userData: Data = NSKeyedArchiver.archivedData(withRootObject: self)
		UserDefaults.standard.set(userData, forKey: CURRENT_USER_KEY)
		UserDefaults.standard.synchronize()
	}
	
	internal class func clearCurrentUser() {
		UZUser._currentUser = nil;
//		FBSDKAccessToken.setCurrent(nil)
//		FBSDKProfile.setCurrent(nil)
		
		UserDefaults.standard.removeObject(forKey: CURRENT_USER_KEY)
		UserDefaults.standard.synchronize()
	}
	
	func merge(with user:UZUser!) {
		if self.data == nil {
			self.data = NSMutableDictionary()
		}
		
		let lastToken: String = String(describing: self.token ?? "") // copy to new instance
		self.data!.addEntries(from: user.data! as! [String: AnyHashable])
		self.data!.setObject(lastToken, forKey: "token" as NSCopying)
		parse(user.data)
		
		self.token = lastToken
	}
	
	// MARK: -
	
	public convenience init(data: NSDictionary) {
		self.init()
		
		self.data = data.mutableCopy() as? NSMutableDictionary
		self.parse(data)
	}
	
	public override init() {
		super.init()
	}
	
	required public init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		self.data = aDecoder.decodeObject(forKey: "data") as? NSMutableDictionary
		self.parse(self.data)
	}
	
	override open func encode(with aCoder: NSCoder) {
		if (self.data != nil) {
			aCoder.encode(self.data, forKey: "data")
		}
	}
	
	override func parse(_ data: NSDictionary?) {
		if data != nil {
			let userData 	= data!.value(for: "user", defaultValue: nil) as? NSDictionary ?? data
			
			id				= userData!.string(for: "id", defaultString: "")
			name			= userData!.string(for: "name", defaultString: nil)
			gender			= userData!.string(for: "gender", defaultString: nil)
			email			= userData!.string(for: "email", defaultString: nil)
			mobile			= userData!.string(for: "phone", defaultString: nil)
			token			= userData!.string(for: "token", defaultString: nil)
			facebookId		= userData!.string(for: "fbId", defaultString: nil)
			
//			if let birthdayString = userData!.string(for: "birthday", defaultString: nil) {
//				birthday = birthdayString.length>10 ? Date(fromString: birthdayString, format: .isoDateTimeMilliSec) : Date(fromString: birthdayString, format: .custom("YYYY-MM-dd"))
//			}
			
//			if let fbToken = data!["facebookToken"] as? FBSDKAccessToken {
//				self.facebookToken = fbToken
//			}
//
//			if let fbProfile = data!["facebookProfile"] as? FBSDKProfile {
//				self.facebookProfile = fbProfile
//			}
			
			if token == nil {
				token = data!.string(for: "token", defaultString: nil)
			}

		}
	}
	
	/** Object description */
	override open var description : String {
		return "\(super.description) [\(name ?? "")] [token:\(token ?? "")]"
	}
	
	open override func isEqual(_ object: Any?) -> Bool {
		if object is UZUser {
			return (object as! UZUser).id == self.id
		}
		
		return false
	}
	
	static public func == (lhs: UZUser, rhs: UZUser) -> Bool {
		return lhs.id == rhs.id
	}
	
}


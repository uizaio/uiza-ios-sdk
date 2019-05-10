//
//  SwiftIcon++.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 5/13/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import Foundation
import UIKit

public extension UISegmentedControl {
    
    /**
     This function sets the icon to UISegmentedControl at particular segment index
     
     - Parameter icon: The icon
     - Parameter color: Color for the icon
     - Parameter iconSize: Size of the icon
     - Parameter forSegmentAtIndex: Segment index for the icon
     
     - Since: 1.0.0
     */
    func setIcon(icon: FontType, color: UIColor = .black, iconSize: CGFloat? = nil, forSegmentAtIndex segment: Int) {
        FontLoader.loadFontIfNeeded(fontType: icon)
        let font = UIFont(name: icon.fontName(), size: iconSize ?? 23)
        assert(font != nil, icon.errorAnnounce())
        setTitleTextAttributes([NSAttributedString.Key.font: font!], for: UIControl.State.normal)
        setTitle(icon.text, forSegmentAt: segment)
        tintColor = color
    }
}

public extension UITabBarItem {
    
    /**
     This function sets the icon to UITabBarItem
     
     - Parameter icon: The icon for the UITabBarItem
     - Parameter size: CGSize for the icon
     - Parameter textColor: Color for the icon when UITabBarItem is not selected
     - Parameter backgroundColor: Background color for the icon when UITabBarItem is not selected
     - Parameter selectedTextColor: Color for the icon when UITabBarItem is selected
     - Parameter selectedBackgroundColor: Background color for the icon when UITabBarItem is selected
     
     - Since: 1.0.0
     */
    func setIcon(icon: FontType, size: CGSize? = nil, textColor: UIColor = .black, backgroundColor: UIColor = .clear, selectedTextColor: UIColor = .black, selectedBackgroundColor: UIColor = .clear) {
        
        let tabBarItemImageSize = size ?? CGSize(width: 30, height: 30)
        image = UIImage(icon: icon, size: tabBarItemImageSize, textColor: textColor, backgroundColor: backgroundColor).withRenderingMode(.alwaysOriginal)
        selectedImage = UIImage(icon: icon, size: tabBarItemImageSize, textColor: selectedTextColor, backgroundColor: selectedBackgroundColor).withRenderingMode(.alwaysOriginal)
    }
    
    
    /**
     This function supports stacked icons for UITabBarItem. For details check [Stacked Icons](http://fontawesome.io/examples/#stacked)
     
     - Parameter bgIcon: Background icon of the stacked icons
     - Parameter bgTextColor: Color for the background icon
     - Parameter selectedBgTextColor: Color for the background icon when UITabBarItem is selected
     - Parameter topIcon: Top icon of the stacked icons
     - Parameter topTextColor: Color for the top icon
     - Parameter selectedTopTextColor: Color for the top icon when UITabBarItem is selected
     - Parameter bgLarge: Set if the background icon should be bigger
     - Parameter size: CGSize for the icon
     
     - Since: 1.0.0
     */
    func setIcon(bgIcon: FontType, bgTextColor: UIColor = .black, selectedBgTextColor: UIColor = .black, topIcon: FontType, topTextColor: UIColor = .black, selectedTopTextColor: UIColor = .black, bgLarge: Bool? = true, size: CGSize? = nil) {
        
        let tabBarItemImageSize = size ?? CGSize(width: 15, height: 15)
        image = UIImage(bgIcon: bgIcon, bgTextColor: bgTextColor, bgBackgroundColor: .clear, topIcon: topIcon, topTextColor: topTextColor, bgLarge: bgLarge, size: tabBarItemImageSize).withRenderingMode(.alwaysOriginal)
        selectedImage = UIImage(bgIcon: bgIcon, bgTextColor: selectedBgTextColor, bgBackgroundColor: .clear, topIcon: topIcon, topTextColor: selectedTopTextColor, bgLarge: bgLarge, size: tabBarItemImageSize).withRenderingMode(.alwaysOriginal)
    }
}

public extension UISlider {
    
    /**
     This function sets the icon to the maximum value of UISlider
     
     - Parameter icon: The icon for the maximum value of UISlider
     - Parameter size: CGSize for the icon
     - Parameter textColor: Color for the icon
     - Parameter backgroundColor: Background color for the icon
     
     - Since: 1.0.0
     */
    func setMaximumValueIcon(icon: FontType, customSize: CGSize? = nil, textColor: UIColor = .black, backgroundColor: UIColor = .clear) {
        maximumValueImage = UIImage(icon: icon, size: customSize ?? CGSize(width: 25,height: 25), textColor: textColor, backgroundColor: backgroundColor)
    }
    
    
    /**
     This function sets the icon to the minimum value of UISlider
     
     - Parameter icon: The icon for the minimum value of UISlider
     - Parameter size: CGSize for the icon
     - Parameter textColor: Color for the icon
     - Parameter backgroundColor: Background color for the icon
     
     - Since: 1.0.0
     */
    func setMinimumValueIcon(icon: FontType, customSize: CGSize? = nil, textColor: UIColor = .black, backgroundColor: UIColor = .clear) {
        minimumValueImage = UIImage(icon: icon, size: customSize ?? CGSize(width: 25,height: 25), textColor: textColor, backgroundColor: backgroundColor)
    }
}

public extension UIBarButtonItem {
    
    /**
     This function sets the icon for UIBarButtonItem
     
     - Parameter icon: The icon for the for UIBarButtonItem
     - Parameter iconSize: Size for the icon
     - Parameter color: Color for the icon
     
     - Since: 1.0.0
     */
    func setIcon(icon: FontType, iconSize: CGFloat, color: UIColor = .black) {
        
        FontLoader.loadFontIfNeeded(fontType: icon)
        let font = UIFont(name: icon.fontName(), size: iconSize)
        assert(font != nil, icon.errorAnnounce())
        setTitleTextAttributes([NSAttributedString.Key.font: font!], for: UIControl.State.normal)
        setTitleTextAttributes([NSAttributedString.Key.font: font!], for: UIControl.State.highlighted)
        setTitleTextAttributes([NSAttributedString.Key.font: font!], for: UIControl.State.disabled)
        if #available(iOS 9.0, *) {
            setTitleTextAttributes([NSAttributedString.Key.font: font!], for: UIControl.State.focused)
        } else {
            // Fallback on earlier versions
        }
        title = icon.text
        tintColor = color
    }
    
    
    /**
     This function sets the icon for UIBarButtonItem using custom view
     
     - Parameter icon: The icon for the for UIBarButtonItem
     - Parameter iconSize: Size for the icon
     - Parameter color: Color for the icon
     - Parameter cgRect: CGRect for the whole icon & text
     - Parameter target: Action target
     - Parameter action: Action for the UIBarButtonItem
     
     - Since: 1.5
     */
    func setIcon(icon: FontType, iconSize: CGFloat, color: UIColor = .black, cgRect: CGRect, target: AnyObject?, action: Selector) {
        
        let highlightedColor = color.withAlphaComponent(0.4)
        
        title = nil
        let button = UIButton(frame: cgRect)
        button.setIcon(icon: icon, iconSize: iconSize, color: color, forState: UIControl.State.normal)
        button.setTitleColor(highlightedColor, for: UIControl.State.highlighted)
        button.addTarget(target, action: action, for: UIControl.Event.touchUpInside)
        
        customView = button
    }
    
    
    /**
     This function sets the icon for UIBarButtonItem with text around it with different colors
     
     - Parameter prefixText: The text before the icon
     - Parameter prefixTextColor: The color for the text before the icon
     - Parameter icon: The icon
     - Parameter iconColor: Color for the icon
     - Parameter postfixText: The text after the icon
     - Parameter postfixTextColor: The color for the text after the icon
     - Parameter cgRect: CGRect for the whole icon & text
     - Parameter size: Size of the text
     - Parameter iconSize: Size of the icon
     - Parameter target: Action target
     - Parameter action: Action for the UIBarButtonItem
     
     - Since: 1.5
     */
    func setIcon(prefixText: String, prefixTextColor: UIColor = .black, icon: FontType?, iconColor: UIColor = .black, postfixText: String, postfixTextColor: UIColor = .black, cgRect: CGRect, size: CGFloat?, iconSize: CGFloat? = nil, target: AnyObject?, action: Selector) {
        
        let prefixTextHighlightedColor = prefixTextColor.withAlphaComponent(0.4)
        let iconHighlightedColor = iconColor.withAlphaComponent(0.4)
        let postfixTextHighlightedColor = postfixTextColor.withAlphaComponent(0.4)
        
        title = nil
        let button = UIButton(frame: cgRect)
        button.setIcon(prefixText: prefixText, prefixTextColor: prefixTextColor, icon: icon!, iconColor: iconColor, postfixText: postfixText, postfixTextColor: postfixTextColor, backgroundColor: .clear, forState: UIControl.State.normal, textSize: size, iconSize: iconSize)
        button.setIcon(prefixText: prefixText, prefixTextColor: prefixTextHighlightedColor, icon: icon!, iconColor: iconHighlightedColor, postfixText: postfixText, postfixTextColor: postfixTextHighlightedColor, backgroundColor: .clear, forState: UIControl.State.highlighted, textSize: size, iconSize: iconSize)
        
        button.addTarget(target, action: action, for: UIControl.Event.touchUpInside)
        
        customView = button
    }
    
    
    /**
     This function sets the icon for UIBarButtonItem with text around it with different colors
     
     - Parameter prefixText: The text before the icon
     - Parameter prefixTextColor: The color for the text before the icon
     - Parameter prefixTextColor: The color for the text before the icon
     - Parameter icon: The icon
     - Parameter iconColor: Color for the icon
     - Parameter postfixText: The text after the icon
     - Parameter postfixTextColor: The color for the text after the icon
     - Parameter postfixTextColor: The color for the text after the icon
     - Parameter cgRect: CGRect for the whole icon & text
     - Parameter size: Size of the text
     - Parameter iconSize: Size of the icon
     - Parameter target: Action target
     - Parameter action: Action for the UIBarButtonItem
     
     - Since: 1.5
     */
    func setIcon(prefixText: String, prefixTextFont: UIFont, prefixTextColor: UIColor = .black, icon: FontType?, iconColor: UIColor = .black, postfixText: String, postfixTextFont: UIFont, postfixTextColor: UIColor = .black, cgRect: CGRect, iconSize: CGFloat? = nil, target: AnyObject?, action: Selector) {
        
        let prefixTextHighlightedColor = prefixTextColor.withAlphaComponent(0.4)
        let iconHighlightedColor = iconColor.withAlphaComponent(0.4)
        let postfixTextHighlightedColor = postfixTextColor.withAlphaComponent(0.4)
        
        title = nil
        let button = UIButton(frame: cgRect)
        button.setIcon(prefixText: prefixText, prefixTextFont: prefixTextFont, prefixTextColor: prefixTextColor, icon: icon, iconColor: iconColor, postfixText: postfixText, postfixTextFont: postfixTextFont, postfixTextColor: postfixTextColor, backgroundColor: .clear, forState: UIControl.State.normal, iconSize: iconSize)
        button.setIcon(prefixText: prefixText, prefixTextFont: prefixTextFont, prefixTextColor: prefixTextHighlightedColor, icon: icon, iconColor: iconHighlightedColor, postfixText: postfixText, postfixTextFont: postfixTextFont, postfixTextColor: postfixTextHighlightedColor, backgroundColor: .clear, forState: UIControl.State.highlighted, iconSize: iconSize)
        button.addTarget(target, action: action, for: UIControl.Event.touchUpInside)
        
        customView = button
    }
}

public extension UIStepper {
    
    /**
     This function sets the increment icon for UIStepper
     
     - Parameter icon: The icon for the for UIStepper
     - Parameter forState: Control state of the increment icon of the UIStepper
     
     - Since: 1.0.0
     */
    func setIncrementIcon(icon: FontType?, forState state: UIControl.State) {
        
        let backgroundSize = CGSize(width: 20, height: 20)
        let image = UIImage(icon: icon!, size: backgroundSize)
        setIncrementImage(image, for: state)
    }
    
    
    /**
     This function sets the decrement icon for UIStepper
     
     - Parameter icon: The icon for the for UIStepper
     - Parameter forState: Control state of the decrement icon of the UIStepper
     
     - Since: 1.0.0
     */
    func setDecrementIcon(icon: FontType?, forState state: UIControl.State) {
        
        let backgroundSize = CGSize(width: 20, height: 20)
        let image = UIImage(icon: icon!, size: backgroundSize)
        setDecrementImage(image, for: state)
    }
}

public extension UITextField {
    
    /**
     This function sets the icon for the right view of the UITextField
     
     - Parameter icon: The icon for the right view of the UITextField
     - Parameter rightViewMode: UITextFieldViewMode for the right view of the UITextField
     - Parameter textColor: Color for the icon
     - Parameter backgroundColor: Background color for the icon
     - Parameter size: CGSize for the icon
     
     - Since: 1.0.0
     */
    func setRightViewIcon(icon: FontType, rightViewMode: UITextField.ViewMode = .always, textColor: UIColor = .black, backgroundColor: UIColor = .clear, size: CGSize? = nil) {
        FontLoader.loadFontIfNeeded(fontType: icon)
        
        let image = UIImage(icon: icon, size: size ?? CGSize(width: 30, height: 30), textColor: textColor, backgroundColor: backgroundColor)
        let imageView = UIImageView.init(image: image)
        
        self.rightView = imageView
        self.rightViewMode = rightViewMode
    }
    
    
    /**
     This function sets the icon for the left view of the UITextField
     
     - Parameter icon: The icon for the left view of the UITextField
     - Parameter leftViewMode: UITextFieldViewMode for the left view of the UITextField
     - Parameter textColor: Color for the icon
     - Parameter backgroundColor: Background color for the icon
     - Parameter size: CGSize for the icon
     
     - Since: 1.0.0
     */
    func setLeftViewIcon(icon: FontType, leftViewMode: UITextField.ViewMode = .always, textColor: UIColor = .black, backgroundColor: UIColor = .clear, size: CGSize? = nil) {
        FontLoader.loadFontIfNeeded(fontType: icon)
        
        let image = UIImage(icon: icon, size: size ?? CGSize(width: 30, height: 30), textColor: textColor, backgroundColor: backgroundColor)
        let imageView = UIImageView.init(image: image)
        
        self.leftView = imageView
        self.leftViewMode = leftViewMode
    }
}

public extension UIViewController {
    
    /**
     This function sets the icon for the title of navigation bar
     
     - Parameter icon: The icon for the title of navigation bar
     - Parameter iconSize: Size of the icon
     - Parameter textColor: Color for the icon
     
     - Since: 1.0.0
     */
    func setTitleIcon(icon: FontType, iconSize: CGFloat? = nil, color: UIColor = .black) {
        let size = iconSize ?? 23
        FontLoader.loadFontIfNeeded(fontType: icon)
        let font = UIFont(name: icon.fontName(), size: size)
        assert(font != nil, icon.errorAnnounce())
        let titleAttributes = [NSAttributedString.Key.font: font!, NSAttributedString.Key.foregroundColor: color]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        title = icon.text
    }
}

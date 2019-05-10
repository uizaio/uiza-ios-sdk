//  The MIT License (MIT)
//
//  Copyright © 2017 Saurabh Rane
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import UIKit

public extension UIImage {
    
    /**
     This init function sets the icon to UIImage
     
     - Parameter icon: The icon for the UIImage
     - Parameter size: CGSize for the icon
     - Parameter textColor: Color for the icon
     - Parameter backgroundColor: Background color for the icon
     
     - Since: 1.0.0
    */
	convenience init(icon: FontType, size: CGSize, textColor: UIColor = .black, backgroundColor: UIColor = .clear) {
        FontLoader.loadFontIfNeeded(fontType: icon)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        let fontAspectRatio: CGFloat = 1.28571429
        let fontSize = min(size.width / fontAspectRatio, size.height)
        let font = UIFont(name: icon.fontName(), size: fontSize)
        assert(font != nil, icon.errorAnnounce())
        let attributes = [NSAttributedString.Key.font: font!, NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.backgroundColor: backgroundColor, NSAttributedString.Key.paragraphStyle: paragraph]
        let lineHeight = font!.lineHeight
        let attributedString = NSAttributedString(string: icon.text!, attributes: attributes)
        UIGraphicsBeginImageContextWithOptions(size, false , 0.0)
        attributedString.draw(in: CGRect(x: 0, y: (size.height - lineHeight) * 0.5, width: size.width, height: lineHeight))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = image {
            self.init(cgImage: image.cgImage!, scale: image.scale, orientation: image.imageOrientation)
        } else {
            self.init()
        }
    }
    
    /**
     This init function adds support for stacked icons. For details check [Stacked Icons](http://fontawesome.io/examples/#stacked)
     
     - Parameter bgIcon: Background icon of the stacked icons
     - Parameter bgTextColor: Color for the background icon
     - Parameter bgBackgroundColor: Background color for the background icon
     - Parameter topIcon: Top icon of the stacked icons
     - Parameter topTextColor: Color for the top icon
     - Parameter bgLarge: Set if the background icon should be bigger
     - Parameter size: CGSize for the UIImage
     
     - Since: 1.0.0
     */
	convenience init(bgIcon: FontType, bgTextColor: UIColor = .black, bgBackgroundColor: UIColor = .clear, topIcon: FontType, topTextColor: UIColor = .black, bgLarge: Bool? = true, size: CGSize? = nil) {
        
        FontLoader.loadFontIfNeeded(fontType: bgIcon)
        FontLoader.loadFontIfNeeded(fontType: topIcon)
        
        let bgSize: CGSize!
        let topSize: CGSize!
        let bgRect: CGRect!
        let topRect: CGRect!
        
        if bgLarge! {
            topSize = size ?? CGSize(width: 30, height: 30)
            bgSize = CGSize(width: 2 * topSize.width, height: 2 * topSize.height)
            
        } else {
            
            bgSize = size ?? CGSize(width: 30, height: 30)
            topSize = CGSize(width: 2 * bgSize.width, height: 2 * bgSize.height)
        }
        
        let bgImage = UIImage.init(icon: bgIcon, size: bgSize, textColor: bgTextColor)
        let topImage = UIImage.init(icon: topIcon, size: topSize, textColor: topTextColor)
        
        if bgLarge! {
            bgRect = CGRect(x: 0, y: 0, width: bgSize.width, height: bgSize.height)
            topRect = CGRect(x: topSize.width/2, y: topSize.height/2, width: topSize.width, height: topSize.height)
            UIGraphicsBeginImageContextWithOptions(bgImage.size, false, 0.0)
            
        } else {
            topRect = CGRect(x: 0, y: 0, width: topSize.width, height: topSize.height)
            bgRect = CGRect(x: bgSize.width/2, y: bgSize.height/2, width: bgSize.width, height: bgSize.height)
            UIGraphicsBeginImageContextWithOptions(topImage.size, false, 0.0)
            
        }
        
        bgImage.draw(in: bgRect)
        topImage.draw(in: topRect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = image {
            self.init(cgImage: image.cgImage!, scale: image.scale, orientation: image.imageOrientation)
        } else {
            self.init()
        }
    }
}

public extension UIImageView {
    
    /**
     This function sets the icon to UIImageView
     
     - Parameter icon: The icon for the UIImageView
     - Parameter textColor: Color for the icon
     - Parameter backgroundColor: Background color for the icon
     - Parameter size: CGSize for the UIImage
     
     - Since: 1.0.0
     */
    func setIcon(icon: FontType, textColor: UIColor = .black, backgroundColor: UIColor = .clear, size: CGSize? = nil) {
        self.image = UIImage(icon: icon, size: size ?? frame.size, textColor: textColor, backgroundColor: backgroundColor)
    }
}

public extension UILabel {
    
    /**
     This function sets the icon to UILabel
     
     - Parameter icon: The icon for the UILabel
     - Parameter iconSize: Size of the icon
     - Parameter textColor: Color for the icon
     - Parameter backgroundColor: Background color for the icon
     
     - Since: 1.0.0
     */
	func setIcon(icon: FontType, iconSize: CGFloat, color: UIColor = .black, bgColor: UIColor = .clear) {
        self.setIcons(prefixText: "", prefixTextColor: UIColor.clear, prefixTextFont: self.font, icons: [icon], iconsSize: iconSize, iconsColor: color, bgColor: bgColor, postfixText: "", postfixTextColor: UIColor.clear, postfixTextFont: self.font)
    }
    
    
    /**
     This function sets the icons to UILabel
     
     - Parameter icons: The icons array for the UILabel
     - Parameter iconSize: Size of all icons
     - Parameter textColor: Color for all icons
     - Parameter backgroundColor: Background color for all icon
     
     - Since: 1.1.0
     */
    fileprivate func setIcons(prefixText: String, prefixTextColor: UIColor, prefixTextFont: UIFont, icons: [FontType], iconsSize: CGFloat, iconsColor: UIColor, bgColor: UIColor, postfixText: String, postfixTextColor: UIColor, postfixTextFont: UIFont) {
        self.text = nil
        
        backgroundColor = bgColor
        textAlignment = .center
        attributedText = getAttributedString(prefixText: prefixText, prefixTextColor: prefixTextColor, prefixTextFont: prefixTextFont, icons: icons, iconsSize: iconsSize, iconsColor: iconsColor, postfixText: postfixText, postfixTextColor: postfixTextColor, postfixTextFont: postfixTextFont)
    }
    
	func setIcons(prefixText: String? = nil, prefixTextFont: UIFont? = nil, prefixTextColor: UIColor? = nil, icons: [FontType], iconColor: UIColor? = nil, postfixText: String? = nil, postfixTextFont: UIFont? = nil, postfixTextColor: UIColor? = nil, iconSize: CGFloat? = nil, bgColor: UIColor? = nil) {
        self.setIcons(prefixText: prefixText ?? "", prefixTextColor: prefixTextColor ?? self.textColor, prefixTextFont: prefixTextFont ?? self.font, icons: icons, iconsSize: iconSize ?? self.font.pointSize, iconsColor: iconColor ?? self.textColor, bgColor: bgColor ?? UIColor.clear, postfixText: postfixText ?? "", postfixTextColor: postfixTextColor ?? self.textColor, postfixTextFont: postfixTextFont ?? self.font)
    }
    
    
    /**
     This function sets the icon to UILabel with text around it with different colors
     
     - Parameter prefixText: The text before the icon
     - Parameter prefixTextColor: The color for the text before the icon
     - Parameter icon: The icon
     - Parameter iconColor: Color for the icon
     - Parameter postfixText: The text after the icon
     - Parameter postfixTextColor: The color for the text after the icon
     - Parameter size: Size of the text
     - Parameter iconSize: Size of the icon
     
     - Since: 1.0.0
     */
    func setIcon(prefixText: String, prefixTextColor: UIColor = .black, icon: FontType?, iconColor: UIColor = .black, postfixText: String, postfixTextColor: UIColor = .black, size: CGFloat?, iconSize: CGFloat? = nil) {
        let textFont = self.font.withSize(size ?? self.font.pointSize)
        self.setIcons(prefixText: prefixText, prefixTextColor: prefixTextColor, prefixTextFont: textFont, icons: icon == nil ? [] : [icon!], iconsSize: iconSize ?? self.font.pointSize, iconsColor: iconColor, bgColor: UIColor.clear, postfixText: postfixText, postfixTextColor: postfixTextColor, postfixTextFont: textFont)
    }
    
    
    /**
     This function sets the icon to UILabel with text around it with different fonts & colors
     
     - Parameter prefixText: The text before the icon
     - Parameter prefixTextFont: The font for the text before the icon
     - Parameter prefixTextColor: The color for the text before the icon
     - Parameter icon: The icon
     - Parameter iconColor: Color for the icon
     - Parameter postfixText: The text after the icon
     - Parameter postfixTextFont: The font for the text after the icon
     - Parameter postfixTextColor: The color for the text after the icon
     - Parameter iconSize: Size of the icon
     
     - Since: 1.0.0
     */
    func setIcon(prefixText: String, prefixTextFont: UIFont, prefixTextColor: UIColor = .black, icon: FontType?, iconColor: UIColor = .black, postfixText: String, postfixTextFont: UIFont, postfixTextColor: UIColor = .black, iconSize: CGFloat? = nil) {
        self.setIcons(prefixText: prefixText, prefixTextColor: prefixTextColor, prefixTextFont: prefixTextFont, icons: icon == nil ? [] : [icon!], iconsSize: iconSize ?? self.font.pointSize, iconsColor: iconColor, bgColor: UIColor.clear, postfixText: postfixText, postfixTextColor: postfixTextColor, postfixTextFont: prefixTextFont)
        
    }
}

public extension UIButton {
    
    fileprivate func setIcons(prefixText: String, prefixTextColor: UIColor, prefixTextFont: UIFont, icons: [FontType], iconsSize: CGFloat, iconsColor: UIColor, bgColor: UIColor, postfixText: String, postfixTextColor: UIColor, postfixTextFont: UIFont, forState state: UIControl.State) {
        guard let titleLabel = self.titleLabel else { return }
        let attributedText = getAttributedString(prefixText: prefixText, prefixTextColor: prefixTextColor, prefixTextFont: prefixTextFont, icons: icons, iconsSize: iconsSize, iconsColor: iconsColor, postfixText: postfixText, postfixTextColor: postfixTextColor, postfixTextFont: postfixTextFont)
        self.setAttributedTitle(attributedText, for: state)
        titleLabel.textAlignment = .center
        self.backgroundColor = bgColor
    }
    
    func setIcons(prefixText: String? = nil, prefixTextFont: UIFont? = nil, prefixTextColor: UIColor? = nil, icons: [FontType], iconColor: UIColor? = nil, postfixText: String? = nil, postfixTextFont: UIFont? = nil, postfixTextColor: UIColor? = nil, iconSize: CGFloat? = nil, bgColor: UIColor? = nil, forState state: UIControl.State) {
        guard let titleLabel = self.titleLabel else { return }
        self.setIcons(prefixText: prefixText ?? "", prefixTextColor: prefixTextColor ?? titleLabel.textColor, prefixTextFont: prefixTextFont ?? titleLabel.font, icons: icons, iconsSize: iconSize ?? titleLabel.font.pointSize, iconsColor: iconColor ?? titleLabel.textColor, bgColor: bgColor ?? self.backgroundColor ?? UIColor.clear, postfixText: postfixText ?? "", postfixTextColor: postfixTextColor ?? titleLabel.textColor, postfixTextFont: postfixTextFont ?? titleLabel.font, forState: state)
    }
    
    /**
     This function sets the icon to UIButton
     
     - Parameter icon: The icon for the UIButton
     - Parameter iconSize: Size of the icon
     - Parameter color: Color for the icon
     - Parameter backgroundColor: Background color for the UIButton
     - Parameter forState: Control state of the UIButton
     
     - Since: 1.1
     */
    func setIcon(icon: FontType, iconSize: CGFloat? = nil, color: UIColor = .black, backgroundColor: UIColor = .clear, forState state: UIControl.State) {
        self.setIcons(icons: [icon], iconColor: color, iconSize: iconSize, bgColor: backgroundColor, forState: state)
    }
    
    
    /**
     This function sets the icon to UIButton with text around it with different colors
     
     - Parameter prefixText: The text before the icon
     - Parameter prefixTextColor: The color for the text before the icon
     - Parameter icon: The icon
     - Parameter iconColor: Color for the icon
     - Parameter postfixText: The text after the icon
     - Parameter postfixTextColor: The color for the text after the icon
     - Parameter backgroundColor: Background color for the UIButton
     - Parameter forState: Control state of the UIButton
     - Parameter textSize: Size of the text
     - Parameter iconSize: Size of the icon
     
     - Since: 1.1
     */
    func setIcon(prefixText: String, prefixTextColor: UIColor = .black, icon: FontType, iconColor: UIColor = .black, postfixText: String, postfixTextColor: UIColor = .black, backgroundColor: UIColor = .clear, forState state: UIControl.State, textSize: CGFloat? = nil, iconSize: CGFloat? = nil) {
        guard let titleLabel = self.titleLabel else { return }
        let textFont = titleLabel.font.withSize(textSize ?? titleLabel.font.pointSize)
        self.setIcons(prefixText: prefixText, prefixTextFont: textFont, prefixTextColor: prefixTextColor, icons: [icon], iconColor: iconColor, postfixText: postfixText, postfixTextFont: textFont, postfixTextColor: postfixTextColor, iconSize: iconSize, bgColor: backgroundColor, forState: state)
    }
    
    
    
    
    /**
     This function sets the icon to UIButton with text around it with different fonts & colors
     
     - Parameter prefixText: The text before the icon
     - Parameter prefixTextFont: The font for the text before the icon
     - Parameter prefixTextColor: The color for the text before the icon
     - Parameter icon: The icon
     - Parameter iconColor: Color for the icon
     - Parameter postfixText: The text after the icon
     - Parameter postfixTextFont: The font for the text after the icon
     - Parameter postfixTextColor: The color for the text after the icon
     - Parameter backgroundColor: Background color for the UIButton
     - Parameter forState: Control state of the UIButton
     - Parameter iconSize: Size of the icon
     
     - Since: 1.1
     */
    func setIcon(prefixText: String, prefixTextFont: UIFont, prefixTextColor: UIColor = .black, icon: FontType?, iconColor: UIColor = .black, postfixText: String, postfixTextFont: UIFont, postfixTextColor: UIColor = .black, backgroundColor: UIColor = .clear, forState state: UIControl.State, iconSize: CGFloat? = nil) {
        
        self.setIcons(prefixText: prefixText, prefixTextFont: prefixTextFont, prefixTextColor: prefixTextColor, icons: icon == nil ? [] : [icon!], iconColor: iconColor, postfixText: postfixText, postfixTextFont: postfixTextFont, postfixTextColor: postfixTextColor, iconSize: iconSize, bgColor: backgroundColor, forState: state)
    }
    
    
    /**
     This function sets the icon to UIButton with title below it, with different colors
     
     - Parameter icon: The icon
     - Parameter iconColor: Color for the icon
     - Parameter title: The title
     - Parameter titleColor: Color for the title
     - Parameter backgroundColor: Background color for the button
     - Parameter borderSize: Border size for the button
     - Parameter borderColor: Border color for the button
     - Parameter forState: Control state of the UIButton
     
     - Since: 1.1
     */
    func setIcon(icon: FontType, iconColor: UIColor = .black, title: String, titleColor: UIColor = .black, backgroundColor: UIColor = .clear, borderSize: CGFloat = 1, borderColor: UIColor = .clear, forState state: UIControl.State) {
        
        let height = frame.size.height
        let width = frame.size.width
        let gap : CGFloat = 5
        let textHeight : CGFloat = 15
        
        let size1 = width - (borderSize * 2 + gap * 2)
        let size2 = height - (borderSize * 2 + gap * 3 + textHeight)
        let imageOrigin : CGFloat = borderSize + gap
        let textTop : CGFloat = imageOrigin + size2 + gap
        let textBottom : CGFloat = borderSize + gap
        let imageBottom : CGFloat = textBottom + textHeight + gap
        
        let image = UIImage.init(icon: icon, size: CGSize(width: size1, height: size2), textColor: iconColor, backgroundColor: backgroundColor)
        imageEdgeInsets = UIEdgeInsets(top: imageOrigin, left: imageOrigin, bottom: imageBottom, right: imageOrigin)
        titleEdgeInsets = UIEdgeInsets(top: textTop, left: -image.size.width, bottom: textBottom, right: 0.0)
        
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderSize
        setImage(image, for: state)
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.1
        setTitle(title, for: state)
        setTitleColor(titleColor, for: state)
        self.backgroundColor = backgroundColor
    }

    
    /**
     This function sets the icon to UIButton with title (custom font) below it, with different colors
     
     - Parameter icon: The icon
     - Parameter iconColor: Color for the icon
     - Parameter title: The title
     - Parameter titleColor: Color for the title
     - Parameter font: The font for the title below the icon
     - Parameter backgroundColor: Background color for the button
     - Parameter borderSize: Border size for the button
     - Parameter borderColor: Border color for the button
     - Parameter forState: Control state of the UIButton

     - Since: 1.1
     */
    func setIcon(icon: FontType, iconColor: UIColor = .black, title: String, titleColor: UIColor = .black, font: UIFont, backgroundColor: UIColor = .clear, borderSize: CGFloat = 1, borderColor: UIColor = .clear, forState state: UIControl.State) {
        
        setIcon(icon: icon, iconColor: iconColor, title: title, titleColor: titleColor, backgroundColor: backgroundColor, borderSize: borderSize, borderColor: borderColor, forState: state)
        titleLabel?.font = font
    }
    
    
    /**
     This function sets the icon to UIButton with title below it
     
     - Parameter icon: The icon
     - Parameter title: The title
     - Parameter color: Color for the icon & title
     - Parameter backgroundColor: Background color for the button
     - Parameter borderSize: Border size for the button
     - Parameter borderColor: Border color for the button
     - Parameter forState: Control state of the UIButton
     
     - Since: 1.1
     */
    func setIcon(icon: FontType, title: String, color: UIColor = .black, backgroundColor: UIColor = .clear, borderSize: CGFloat = 1, borderColor: UIColor = .clear, forState state: UIControl.State) {
        
        setIcon(icon: icon, iconColor: color, title: title, titleColor: color, backgroundColor: backgroundColor, borderSize: borderSize, borderColor: borderColor, forState: state)
    }
    
    
    /**
     This function sets the icon to UIButton with title (custom font) below it
     
     - Parameter icon: The icon
     - Parameter title: The title
     - Parameter font: The font for the title below the icon
     - Parameter color: Color for the icon & title
     - Parameter backgroundColor: Background color for the button
     - Parameter borderSize: Border size for the button
     - Parameter borderColor: Border color for the button
     - Parameter forState: Control state of the UIButton

     - Since: 1.1
     */
    func setIcon(icon: FontType, title: String, font: UIFont, color: UIColor = .black, backgroundColor: UIColor = .clear, borderSize: CGFloat = 1, borderColor: UIColor = .clear, forState state: UIControl.State) {
        
        setIcon(icon: icon, iconColor: color, title: title, titleColor: color, font: font, backgroundColor: backgroundColor, borderSize: borderSize, borderColor: borderColor, forState: state)
    }
}

private class FontLoader {
    /**
     This utility function helps loading the font if not loaded already

     - Parameter fontType: The type of the font

     */
    static func loadFontIfNeeded(fontType : FontType) {
        let fileName = fontType.fileName()
        let fontName = fontType.fontName()

        if !loadedFontsTracker[fontName]! {
            let bundle = Bundle(for: FontLoader.self)
            var fontURL: URL!
            let identifier = bundle.bundleIdentifier

            if (identifier?.hasPrefix("org.cocoapods"))! {
                fontURL = bundle.url(forResource: fileName, withExtension: "ttf", subdirectory: "SwiftIcons.bundle")
            } else {
                fontURL = bundle.url(forResource: fileName, withExtension: "ttf")!
            }

            let data = try! Data(contentsOf: fontURL)
            let provider = CGDataProvider(data: data as CFData)
            let font = CGFont(provider!)!

            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterGraphicsFont(font, &error) {
                let errorDescription: CFString = CFErrorCopyDescription(error!.takeUnretainedValue())
                let nsError = error!.takeUnretainedValue() as AnyObject as! NSError
                NSException(name: NSExceptionName.internalInconsistencyException, reason: errorDescription as String, userInfo: [NSUnderlyingErrorKey: nsError]).raise()
            } else {
                loadedFontsTracker[fontName] = true
            }
        }
    }
}

private var loadedFontsTracker: [String: Bool] = ["dripicons-v2": false,
                                                  "emoji": false,
                                                  "FontAwesome5FreeRegular": false,
                                                  "FontAwesome5BrandsRegular": false,
                                                  "FontAwesome5FreeSolid": false,
                                                  "icofont": false,
                                                  "Ionicons": false,
                                                  "Linearicons-Free": false,
                                                  "map-icons": false,
                                                  "MaterialIcons-Regular": false,
                                                  "open-iconic": false,
                                                  "StateFace-Regular": false,
                                                  "WeatherIcons-Regular": false,
                                                  "typicons": false,
]

protocol FontProtocol {
    func errorAnnounce() -> String
    func familyName() -> String
    func fileName() -> String
    func fontName() -> String
}

fileprivate func getAttributedString(prefixText: String, prefixTextColor: UIColor, prefixTextFont: UIFont, icons: [FontType], iconsSize: CGFloat, iconsColor: UIColor, postfixText: String, postfixTextColor: UIColor, postfixTextFont: UIFont) -> NSAttributedString {
    icons.forEach { FontLoader.loadFontIfNeeded(fontType: $0) }
    let iconFonts = icons.map { UIFont(name: $0.fontName(), size: iconsSize) }
    for (index, element) in iconFonts.enumerated() {
        assert(element != nil, icons[index].errorAnnounce())
    }
    
    let iconsString = icons.reduce("") { $0 + ($1.text ?? "") }
    let resultAttrString = NSMutableAttributedString(string: "\(prefixText)\(iconsString)\(postfixText)")
    
    //add prefix text attribute
    resultAttrString.addAttributes([
        NSAttributedString.Key.font: prefixTextFont,
        NSAttributedString.Key.foregroundColor: prefixTextColor,
        ], range: NSMakeRange(0, prefixText.count))
    
    //add icons attribute
    resultAttrString.addAttribute(NSAttributedString.Key.foregroundColor, value: iconsColor, range: NSMakeRange(prefixText.count, iconsString.count))
    for (index, _) in icons.enumerated() {
        resultAttrString.addAttribute(NSAttributedString.Key.font, value: iconFonts[index]!, range: NSMakeRange(prefixText.count + index, 1))
    }
    
    //add postfix text attribute
    if postfixText.count > 0 {
        resultAttrString.addAttributes([
            NSAttributedString.Key.font: postfixTextFont,
            NSAttributedString.Key.foregroundColor: postfixTextColor
            ], range: NSMakeRange(prefixText.count + iconsString.count, postfixText.count))
    }
    
    return resultAttrString
}

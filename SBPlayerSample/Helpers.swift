//
//  Commons.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/8/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import Foundation
import UIKit

class Helpers {
	static let settings = NSDictionary.init(contentsOfFile: Bundle.main.path(forResource: "Configs", ofType: "plist")!)! as! [String:String]
	
	static func requestURL<T>(_ url: String, _ callback: ((T?) -> Void)?) {
		guard let urlObj = URL(string: url) else {
			print("\(type(of: self)) Error: Invalid URL format: \(url)")
			return
		}
		
		requestURL(URLRequest(url: urlObj), callback)
	}
	
	static func requestURL(_ url: String) {
		requestURL(url, nil as ((Data?) -> Void)?)
	}
	
	static func requestURL<T>(_ urlRequest: URLRequest, _ callback: ((T?) -> Void)?) {
		let requestTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
			let reqText = "\n\(urlRequest.url?.absoluteString ?? "")\nMethod: \(urlRequest.httpMethod ?? "")\nHeader: \(String(describing: urlRequest.allHTTPHeaderFields))"
			
			if let error = error {
				print("\(type(of: self)) Error: \(error.localizedDescription)\(reqText)")
				callback?(nil)
				return
			}
			
			guard let response = response as? HTTPURLResponse else {
				print("\(type(of: self)) Error: No response from server.\(reqText)")
				callback?(nil)
				return
			}
			
			guard case 200..<300 = response.statusCode else {
				print("\(type(of: self)) Error: Invalid server response (\(response)).\(reqText)")
				callback?(nil)
				return
			}
			
			guard let data = data else {
				print("\(type(of: self)) Error: Unable to get data.\(reqText)")
				callback?(nil)
				return
			}
			
			switch T.self {
			case is String.Type:
				if let text = String(data: data, encoding: String.Encoding.utf8) {
					callback?(text as? T)
				}
				else {
					print("\(type(of: self)) Error: Unable to get text response.\(reqText)")
					callback?(nil)
				}
			case is Data.Type:
				callback?(data as? T)
			default:
				callback?(nil)
			}
		}
		
		requestTask.resume()
	}
	
	static func requestURL(_ urlRequest: URLRequest) {
		requestURL(urlRequest, nil as ((Data?) -> Void)?)
	}
	
	static func requestURLJson(_ url: String, _ callback: @escaping (AnyObject?) -> Void) {
		requestURL(url) { (data: Data?) in
			var jsonOpt: AnyObject?
			
			do {
				if let data = data {
					jsonOpt = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
				}
				else {
					print("\(type(of: self)) Error getting JSON data.")
				}
			}
			catch {
				print("\(type(of: self)) Error parsing JSON string.")
			}
			
			callback(jsonOpt)
		}
	}
}

extension UIColor {
	convenience init(_ rgba: UInt) {
		let t = rgba > 0xFFFFFF ? 3 : 2
		
		var array = [CGFloat](repeating: 1.0, count: 4)
		var n: UInt
		
		for i in 0...t {
			n = UInt((t - i)*8)
			array[i] = CGFloat((rgba & 0xFF << n) >> n)/255.0
		}
		
		self.init(red: array[0], green: array[1], blue: array[2], alpha: array[3])
	}
}

public extension UIImage {
	/**
	Tint, Colorize image with given tint color<br><br>
	This is similar to Photoshop's "Color" layer blend mode<br><br>
	This is perfect for non-greyscale source images, and images that have both highlights and shadows that should be preserved<br><br>
	white will stay white and black will stay black as the lightness of the image is preserved<br><br>
	
	<img src="http://yannickstephan.com/easyhelper/tint1.png" height="70" width="120"/>
	
	**To**
	
	<img src="http://yannickstephan.com/easyhelper/tint2.png" height="70" width="120"/>
	
	- parameter tintColor: UIColor
	
	- returns: UIImage
	*/
	public func tintPhoto(_ tintColor: UIColor) -> UIImage {
		
		return modifiedImage { context, rect in
			// draw black background - workaround to preserve color of partially transparent pixels
			context.setBlendMode(.normal)
			UIColor.black.setFill()
			context.fill(rect)
			
			// draw original image
			context.setBlendMode(.normal)
			context.draw(self.cgImage!, in: rect)
			
			// tint image (loosing alpha) - the luminosity of the original image is preserved
			context.setBlendMode(.color)
			tintColor.setFill()
			context.fill(rect)
			
			// mask by alpha values of original image
			context.setBlendMode(.destinationIn)
			context.draw(self.cgImage!, in: rect)
		}
	}
	/**
	Tint Picto to color
	
	- parameter fillColor: UIColor
	
	- returns: UIImage
	*/
	public func tintPicto(_ fillColor: UIColor) -> UIImage {
		
		return modifiedImage { context, rect in
			// draw tint color
			context.setBlendMode(.normal)
			fillColor.setFill()
			context.fill(rect)
			
			// mask by alpha values of original image
			context.setBlendMode(.destinationIn)
			context.draw(self.cgImage!, in: rect)
		}
	}
	/**
	Modified Image Context, apply modification on image
	
	- parameter draw: (CGContext, CGRect) -> Void)
	
	- returns: UIImage
	*/
	fileprivate func modifiedImage(_ draw: (CGContext, CGRect) -> Void) -> UIImage {
		
		// using scale correctly preserves retina images
		UIGraphicsBeginImageContextWithOptions(size, false, scale)
		let context: CGContext! = UIGraphicsGetCurrentContext()
		assert(context != nil)
		
		// correctly rotate image
		context.translateBy(x: 0, y: size.height)
		context.scaleBy(x: 1.0, y: -1.0)
		
		let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
		
		draw(context, rect)
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image!
	}
}

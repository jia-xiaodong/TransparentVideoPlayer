//
//  ViewController.swift
//  TransparentVideoPlayer
//
//  Created by jia xiaodong on 7/23/20.
//  Copyright © 2020 homemade. All rights reserved.
//

import Cocoa
import AVKit
import AVFoundation

class ViewController: NSViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		// Load our player item
		let videoPath = NSBundle.mainBundle().pathForResource("playdoh-bat", ofType: "mp4")
		let itemUrl = NSURL(fileURLWithPath: videoPath!, isDirectory: false)
		let playerItem = createTransparentItem(itemUrl)
		playerItem.addObserver(self, forKeyPath: "status", options: .New, context: nil)
		let player = AVPlayer(playerItem: playerItem)
		
		// create a AVPlayerLayer
		let playerLayer = AVPlayerLayer(player: player)
		
		// initial position
		let viewCenter = CGPoint(x: view.bounds.width/2, y: view.bounds.height/2)
		let anchorCenter = CGPoint(x: 0.5, y: 0.5)
		playerLayer.bounds = view.bounds
		playerLayer.position = viewCenter
		playerLayer.anchorPoint = anchorCenter
		
		// the only reason I use AVPlayerLayer: it can setup pixel-buffer format
		playerLayer.pixelBufferAttributes = [
			(kCVPixelBufferPixelFormatTypeKey as String): NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
		view.layer?.addSublayer(playerLayer)
		
		// [debug] check if color is effective on layer
		/*
		playerLayer.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.0)
		view.layer?.backgroundColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.5)
		*/
		
		// FIXME: I figured out only one method to retrieve NSWindow instances.
		// make window transparent
		let windows = NSApplication.sharedApplication().windows
		for i in windows {
			i.opaque = false
			i.backgroundColor = NSColor.clearColor()
		}
	}

	override var representedObject: AnyObject? {
		didSet {
		// Update the view, if already loaded.
		}
	}
	
	var playerLayer: AVPlayerLayer? {
		let layers = view.layer?.sublayers?.filter() { $0 is AVPlayerLayer }
		return layers?.first as? AVPlayerLayer
	}

	// MARK: - Player Item Configuration
	
	func createTransparentItem(url: NSURL) -> AVPlayerItem {
		let asset = AVAsset(URL: url)
		let playerItem = AVPlayerItem(asset: asset)
		// Set the video so that seeking also renders with transparency
		playerItem.seekingWaitsForVideoCompositionRendering = true
		// Apply a video composition (which applies our custom filter)
		playerItem.videoComposition = createVideoComposition(for: asset)
		return playerItem
	}
	
	func createVideoComposition(for asset: AVAsset) -> AVVideoComposition {
		let filter = AlphaFrameFilter(renderingMode: .builtInFilter)
		let composition = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
			do {
				let (inputImage, maskImage) = request.sourceImage.verticalSplit()
				let outputImage = try filter.process(inputImage, mask: maskImage)
				return request.finishWithImage(outputImage, context: nil)
			} catch {
				debugPrint("Video composition error")
				return request.finishWithError(NSError(domain: "placeholder", code: 0, userInfo: nil))
			}
		})
		
		composition.renderSize = CGSizeApplyAffineTransform(asset.videoSize, CGAffineTransformMakeScale(1.0, 0.5))
		return composition
	}
	
	// MARK: - Key-value-observing on AVPlayerItem
	// Only called once after AVPlayerItem is loaded
	override func observeValueForKeyPath(keyPath: String?,
								 ofObject object: AnyObject?,
								          change: [String : AnyObject]?,
										 context: UnsafeMutablePointer<Void>)
	{
		if keyPath?.compare("status") == NSComparisonResult.OrderedSame {
			let status: AVPlayerItemStatus
			if let statusNumber = change?[NSKeyValueChangeNewKey] as? NSNumber {
				status = AVPlayerItemStatus(rawValue: statusNumber.integerValue)!
			} else {
				status = .Unknown
			}
			// automatically play after play-item is loaded.
			if let playerItem = (object as? AVPlayerItem) {
				switch status {
				case .Failed:
					debugPrint(playerItem.error?.localizedDescription)
				case .ReadyToPlay:
					// resize View
					let size = playerItem.presentationSize
					view.bounds = NSRect(origin: .zero, size: size)
					let viewCenter = CGPoint(x: size.width/2, y: size.height/2)
					let anchorCenter = CGPoint(x: 0.5, y: 0.5)
					playerLayer?.bounds = view.bounds
					playerLayer?.position = viewCenter
					playerLayer?.anchorPoint = anchorCenter
					//
					playerLayer?.player?.play()
				case .Unknown:
					break
				}
				playerItem.removeObserver(self, forKeyPath: "status")
			}
		}
	}
}


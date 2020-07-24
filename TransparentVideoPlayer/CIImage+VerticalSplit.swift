//
//  CIImage+Split.swift
//  MyTransparentVideoExample
//
//  Created by Quentin Fasquel on 27/03/2020.
//  Copyright © 2020 Quentin Fasquel. All rights reserved.
//

import CoreImage

extension CIImage {

    typealias VerticalSplit = (topImage: CIImage, bottomImage: CIImage)

    func verticalSplit() -> VerticalSplit {
		let outputExtent = CGRectApplyAffineTransform(self.extent, CGAffineTransformMakeScale(1.0, 0.5))

        // Get the top region according to Core Image coordinate system, (0,0) being bottom left
		let translate = CGAffineTransformMakeTranslation(0, outputExtent.height)
		let topRegion = CGRectApplyAffineTransform(outputExtent, translate)
		var topImage = self.imageByCroppingToRect(topRegion)
        // Translate topImage back to origin
		topImage = topImage.imageByApplyingTransform(CGAffineTransformInvert(translate))

        let bottomRegion = outputExtent
        let bottomImage = self.imageByCroppingToRect(bottomRegion)

        return (topImage, bottomImage)
    }
}

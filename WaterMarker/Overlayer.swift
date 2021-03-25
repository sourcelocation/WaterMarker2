//
//  Overlayer.swift
//  WaterMarker
//
//  Created by Матвей Анисович on 3/24/21.
//

import Cocoa
import MetalPetal

class Overlayer {
    func overlay(_ img1cg:CGImage, with img2cg:CGImage, scaling: Double, alpha: Double) -> CGImage? {
        let img1 = MTIImage(cgImage: img1cg, isOpaque: false)
        let img2 = MTIImage(cgImage: img2cg, isOpaque: false).unpremultiplyingAlpha()
        
        // Watermark Layer
        let aspectWatermark = Double(img2cg.height) / Double(img2cg.width)
        
        let watermarkWidth = Int(Double(img1cg.width) * scaling)
        let watermarkHeight = Int(scaling * Double(img1cg.width) * Double(aspectWatermark))
        let layer = MTILayer(content: img2, layoutUnit: .pixel, position: CGPoint(x: img1cg.width / 2, y: img1cg.height / 2), size: CGSize(width: watermarkWidth, height: watermarkHeight), rotation: 0, opacity: Float(alpha), blendMode: .normal)
        
        let filter = MTIMultilayerCompositingFilter()
        
        filter.inputBackgroundImage = img1
        filter.layers = [layer]
        
        
        guard let image = filter.outputImage else { return nil }
        
        let options = MTIContextOptions()
        guard let device = MTLCreateSystemDefaultDevice(), let context = try? MTIContext(device: device, options: options) else {
            return nil
        }

        do {
            let filteredImage = try context.makeCGImage(from: image)
            return filteredImage
        } catch {
            print(error)
        }
        return nil
    }
}

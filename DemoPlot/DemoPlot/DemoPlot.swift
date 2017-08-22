//
//  DemoPlot.swift
//

import Cocoa
import CoreGraphics
import plplot

private let BytesPerPixel: Int32 = 4
private let PlotQueue = DispatchQueue(label: "PLPlotWorkQueue")
// Limits any image to ~50MB.
private let MaximumSideLength: Int32 = 3535

public func drawHistogram(desiredSize: CGSize,
                   measurements: [(date: Date, value: Double)],
                   xAxisLabel: String,
                   yAxisLabel: String,
                   graphTitle: String,
                   numberOfBins: Int = 10) -> NSImage {
    return PlotQueue.sync {
        let roundedWidth = Double(desiredSize.width).rounded(.toNearestOrEven)
        let intWidth = Int32(exactly: roundedWidth) ?? Int32.max
        let width = min(intWidth, MaximumSideLength)
        
        let roundedHeight = Double(desiredSize.height).rounded(.toNearestOrEven)
        let intHeight = Int32(exactly: roundedHeight) ?? Int32.max
        let height = min(intHeight, MaximumSideLength)
        
        let bufferLength = Int(BytesPerPixel * width * height)
        
        // imageBuffer is later freed by a Data wrapper
        let imageBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferLength)
        imageBuffer.initialize(to: 0, count: bufferLength)
        
        // choose the output device
        c_plsdev("memcairo")
        
        // set the memory buffer into which PLPlot will draw
        c_plsmema(width, height, imageBuffer)
        
        // initialize plot
        c_plinit()
        
        // set foreground color to black
        c_plcol0(0)
        
        if !measurements.isEmpty {
            let values = measurements.map { $0.value }
            
            let xMin = values.min()!
            let xMax = values.max()!
            
            values.withUnsafeBufferPointer { (buffer) in
                // draw a histogram of the Double values in buffer
                c_plhist(PLINT(buffer.count), buffer.baseAddress, xMin, xMax, Int32(numberOfBins), PL_HIST_DEFAULT | PL_HIST_NOEXPAND)
            }
        }
        else {
            // it's a fatal error to call c_plhist with no values
            // instead, define a viewport in which the labels can draw when no graph is present
            c_plenv(0.0, 100.0, 0.0, 110.0, 0, 0)
        }
        
        // set the x axis, y axis, and title labels
        c_pllab(xAxisLabel, yAxisLabel, graphTitle)
        
        // finalize plot
        c_plend()
        
        let wrappedData = Data(bytesNoCopy: imageBuffer, count: bufferLength, deallocator: .free)
        
        let rawImage = CGImage(width: Int(width),
                               height: Int(height),
                               bitsPerComponent: 8,
                               bitsPerPixel: Int(BytesPerPixel) * 8,
                               bytesPerRow: Int(BytesPerPixel * width),
                               space: CGColorSpace(name: CGColorSpace.sRGB)!,
                               bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                               provider: CGDataProvider(data: wrappedData as CFData)!,
                               decode: nil,
                               shouldInterpolate: false,
                               intent: .defaultIntent)!
        return NSImage(cgImage: rawImage, size: NSMakeSize(CGFloat(width), CGFloat(height)))
    }
}

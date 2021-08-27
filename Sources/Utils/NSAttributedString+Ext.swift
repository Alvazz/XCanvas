//
//  NSAttributedString+Ext.swift
//  XCanvas
//
//  Created by chen on 2021/4/24.
//
/*
import Cocoa

extension NSAttributedString {
    
    public func cgPath() -> CGPath {
        let textPath = CGMutablePath()
        let attributedString = NSAttributedString(string: string)
        let line = CTLineCreateWithAttributedString(attributedString)

        // direct cast to typed array fails for some reason
        let runs = (CTLineGetGlyphRuns(line) as [AnyObject]) as! [CTRun]

        for run in runs {
            let attributes: NSDictionary = CTRunGetAttributes(run)
            let font = attributes[kCTFontAttributeName as String] as! CTFont

            let count = CTRunGetGlyphCount(run)

            for index in 0..<count {
                let range = CFRangeMake(index, 1)
                var glyph = CGGlyph()
                CTRunGetGlyphs(run, range, &glyph)

                var position = CGPoint()
                CTRunGetPositions(run, range, &position)

                guard let letterPath = CTFontCreatePathForGlyph(font, glyph, nil) else { continue }
//                let transform = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: position.x, ty: position.y)
                let transform = CGAffineTransform(translationX: position.x, y: position.y)
                    .scaledBy(x: 1, y: 1)
                textPath.addPath(letterPath, transform: transform)
            }
        }

        return textPath
    }
    
}
*/

//
//  NSBezierPath+StrokeExtensions.h
//  By Matt Gemmell <http://iratescotsman.com/> 
//  and Rainer Brockerhoff <http://www.brockerhoff.net/>
//

#import <Cocoa/Cocoa.h>

@interface NSBezierPath (StrokeExtensions)

- (void)strokeInside;
- (void)strokeInsideWithinRect:(NSRect)clipRect;

@end

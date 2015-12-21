//
//  Callipers.m
//  Callipers
//
//  Created by Simon Cozens on 19/12/2015.
//  Copyright © 2015 Simon Cozens. All rights reserved.
//

#import "Callipers.h"

@implementation Callipers

- (id) init {
	self = [super init];
	NSBundle * thisBundle = [NSBundle bundleForClass:[self class]];
	if (thisBundle) {
		// The toolbar icon:
		_toolBarIcon = [[NSImage alloc] initWithContentsOfFile:[thisBundle pathForImageResource: @"toolbar"]];
		[_toolBarIcon setTemplate:YES];
	}
    segStart1.segId = NSNotFound;
    segEnd1.segId = NSNotFound;
    segStart2.segId = NSNotFound;
    segEnd2.segId = NSNotFound;
    path1 = NULL;
    path2 = NULL;

	return self;
}

- (NSUInteger) interfaceVersion { return 1; }

- (NSUInteger) groupID { return 120; }

- (NSString*) title { return @"Callipers"; }

- (NSString*) trigger { return @"c"; }

- (NSInteger) tempTrigger { return 0; }

- (BOOL) willSelectTempTool:(id) tempTool {	return YES; }

- (void) mouseDown:(NSEvent*)theEvent {
	// Called when the mouse button is clicked.
	_editViewController = [_windowController activeEditViewController];
	// editViewController.graphicView.cursor = [NSCursor closedHandCursor];
    _draggStart = [_editViewController.graphicView convertPoint:[theEvent locationInWindow] fromView: nil];
    NSLog(@"__mouse dragged from : %@", NSStringFromPoint(_draggStart));
}

- (void) mouseDragged:(NSEvent*)theEvent {
	// Called when the mouse is moved with the primary button down.
	NSPoint Loc = [theEvent locationInWindow];
    [_editViewController.graphicView setNeedsDisplay: TRUE];
    NSLog(@"__mouse dragged to : %@", NSStringFromPoint(Loc));

    _draggCurrent = Loc;
    _dragging = true;
}

- (void) mouseUp:(NSEvent*)theEvent {
	// Called when the primary mouse button is released.
	// editViewController.graphicView.cursor = [NSCursor openHandCursor];
    _dragging = false;
}

- (void) drawBackground {
	// Draw in the background, concerns the complete view.
}

/* We do this madness instead of the path's pointAtTime function because
 a) that fails on lines
 b) the path time includes both on-curve and off-curve points (!)
*/

- (NSPoint) myPointOnPath:(GSPath*)path atTime:(myPathTime)t {
    NSArray* seg = path.segments[t.segId];
    if ([ seg count] == 2) {
        NSPoint p1 = [[seg objectAtIndex:0] pointValue];
        NSPoint p2 = [[seg objectAtIndex:1] pointValue];
        CGFloat x = p1.x + (p2.x-p1.x)*fmod(t.t,1.0);
        CGFloat y = p1.y + (p2.y-p1.y)*fmod(t.t,1.0);
        // NSLog(@"p1=[%g,%g] at t(%g)= [%g,%g] p2=[%g,%g]",p1.x,p1.y,fmod(t,1.0),x,y,p2.x,p2.y);
        return NSMakePoint(x, y);
    }
    NSPoint p = GSPointAtTime(
                              [[seg objectAtIndex:0] pointValue],
                              [[seg objectAtIndex:1] pointValue],
                              [[seg objectAtIndex:2] pointValue],
                              [[seg objectAtIndex:3] pointValue],
                              t.t);
    return p;
}

- (void) stepPathTime:(myPathTime*) t by:(float)step {
    t->t += step;
    if (t->t <= 0) { t->t += 1; t->segId--; }
    if (t->t >= 1) { t->t -= 1; t->segId++; }

}

- (int) comparePathTime:(myPathTime) t1 with:(myPathTime)t2 {
    if (t1.segId < t2.segId) return -1;
    if (t1.segId > t2.segId) return 1;
    return t1.t < t2.t ? -1 : t1.t > t2.t ? 1 : 0;
}

- (void) drawForegroundForLayer:(GSLayer *)Layer {
    NSLog(@"Drawing now");
    if (segStart1.segId == NSNotFound || segEnd1.segId == NSNotFound ||
        segStart2.segId == NSNotFound || segEnd2.segId == NSNotFound ||
        !path1 || !path2) {
        if (_dragging) {
            NSLog(@"Drawing the drag");
            NSBezierPath * path = [NSBezierPath bezierPath];
            [path setLineWidth: 2];
            [path moveToPoint: _draggStart];
             _draggCurrent = [_editViewController.graphicView convertPoint:_draggCurrent fromView:nil];
            NSLog(@"converted point : %@", NSStringFromPoint(_draggCurrent));
            [path lineToPoint: _draggCurrent];
            [[NSColor blackColor] set];
            [path stroke];
        }

        return;
    }
    
    int steps = 400;
    CGFloat step1 = ((segEnd1.segId + segEnd1.t) - (segStart1.segId + segStart1.t)) / steps; // XXX
    CGFloat step2 = ((segEnd2.segId + segEnd2.t) - (segStart2.segId + segStart2.t)) / steps;;
    CGFloat maxLen = 0;
    CGFloat minLen = MAXFLOAT;
    CGFloat avgLen = 0;
    myPathTime t1 = segStart1;
    myPathTime t2 = segStart2;
    while ([self comparePathTime:t1 with: segEnd1] < 0) {
        NSPoint p1 = [self myPointOnPath: path1 atTime: t1];
        NSPoint p2 = [self myPointOnPath: path2 atTime: t2];
        CGFloat dist = GSSquareDistance(p1,p2);
        if (dist < minLen) minLen = dist;
        if (dist > maxLen) maxLen = dist;
        avgLen += dist / steps;
        [self stepPathTime:&t1 by:step1];
        [self stepPathTime:&t2 by:step2];
    }

    t1 = segStart1;
    t2 = segStart2;
    while ([self comparePathTime:t1 with: segEnd1] < 0) {
        NSPoint p1 = [self myPointOnPath: path1 atTime: t1];
        NSPoint p2 = [self myPointOnPath: path2 atTime: t2];
        CGFloat dist = GSSquareDistance(p1,p2);
        NSBezierPath * path = [NSBezierPath bezierPath];
        CGFloat distColor = 2*((dist / avgLen) - 1);
        CGFloat b = distColor > 0 ? 0 : -(2*distColor);
        CGFloat r = distColor < 0 ? 0 : 2*distColor;
        CGFloat g = 1-fabs(2*distColor);
        NSColor *c = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:0.75];
        [path setLineWidth: 2];
        [path moveToPoint: p1];
        [path lineToPoint: p2];
        [c set];
        [path stroke];

        [self stepPathTime:&t1 by:step1];
        [self stepPathTime:&t2 by:step2];
    }

    // Draw in the foreground, concerns the complete view.
}

- (void) drawLayer:(GSLayer*)Layer atPoint:(NSPoint)aPoint asActive:(BOOL)Active attributes:(NSDictionary*)Attributes {
	// Draw anythin for this particular layer.
//	[ _editViewController.graphicView drawLayer:Layer atPoint:aPoint asActive:Active attributes: Attributes ];
}

- (void) willActivate {
	// Called when the tool is selected by the user.
	// editViewController.graphicView.cursor = [NSCursor openHandCursor];
}

- (void) willDeactivate {}

@end

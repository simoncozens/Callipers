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
    tool_state = DRAWING_START;
    
    segStart1 = [[SCPathTime alloc] init];
    segStart2 = [[SCPathTime alloc] init];
    segEnd1   = [[SCPathTime alloc] init];
    segEnd2   = [[SCPathTime alloc] init];

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
    _draggStart = [_editViewController.graphicView getActiveLocation: theEvent];
    if (tool_state == DRAWING_START) {
        segStart1 = [segStart1 init];
        segStart2 = [segStart2 init];
    }
    segEnd1 = [segEnd1 init];
    segEnd2 = [segEnd2 init];
//    NSLog(@"__mouse dragged from : %@", NSStringFromPoint(_draggStart));
}

- (void) mouseDragged:(NSEvent*)theEvent {
	// Called when the mouse is moved with the primary button down.
    NSPoint Loc = [_editViewController.graphicView getActiveLocation: theEvent];
    [_editViewController.graphicView setNeedsDisplay: TRUE];
    if ([theEvent modifierFlags] & NSShiftKeyMask) {
        CGFloat dx = fabs(Loc.x - _draggStart.x);
        CGFloat dy = fabs(Loc.y - _draggStart.y);
        if (dx < dy) {
            Loc.x = _draggStart.x;
        } else {
            Loc.y = _draggStart.y;
        }
    }
    _draggCurrent = Loc;
    _dragging = true;
}

- (void) mouseUp:(NSEvent*)theEvent {
	// Called when the primary mouse button is released.
	// editViewController.graphicView.cursor = [NSCursor openHandCursor];
    NSPoint startPoint = _draggStart;
    NSPoint endPoint   = _draggCurrent;
    GSLayer* layer = [_editViewController.graphicView activeLayer];
    _dragging = false;
    NSMutableArray* intersections = [NSMutableArray array];
    /* How many segments does my line intersect? */
    for (GSPath* p in [layer paths]) {
        int i =0;
        NSArray* segs = [p segments];
        while (i < [segs count]) {
            NSArray *thisSeg = [segs objectAtIndex: i];
            if ([thisSeg count] == 2) {
                // Set up line intersection
                NSPoint segstart = [[thisSeg objectAtIndex:0] pointValue];
                NSPoint segend = [[thisSeg objectAtIndex:1] pointValue];
                NSPoint pt = GSIntersectLineLine(startPoint, endPoint, segstart, segend);
                if (pt.x != NSNotFound && pt.y != NSNotFound) {
                    CGFloat t = GSDistance(segstart,pt) / GSDistance(segstart, segend);
                    SCPathTime *intersection = [[SCPathTime alloc] initWithPath:p SegId:i t:t];
                    [intersections addObject: intersection];
                }
            } else {
                NSPoint segstart = [[thisSeg objectAtIndex:0] pointValue];
                NSPoint handle1 = [[thisSeg objectAtIndex:1] pointValue];
                NSPoint handle2 = [[thisSeg objectAtIndex:2] pointValue];
                NSPoint segend = [[thisSeg objectAtIndex:3] pointValue];
                NSArray* localIntersections = GSIntersectBezier3Line(segstart, handle1, handle2, segend, startPoint, endPoint);
                for (id _pt in localIntersections) {
                    NSPoint pt = [_pt pointValue];
                    CGFloat t;
                    [p nearestPointOnPath:pt pathTime:&t];
                    t = fmod(t, 1.0);
                    SCPathTime *intersection = [[SCPathTime alloc] initWithPath:p SegId:i t:t];
                    [intersections addObject: intersection];
                }
            }
            i++;
        }
    }
//    NSLog(@"Found %lu intersections!", (unsigned long)[intersections count]);
    if ([intersections count] != 2) {
        [_editViewController.graphicView setNeedsDisplay: TRUE];
        return;
    }
    
    if (tool_state == DRAWING_START) {
        tool_state = DRAWING_END;
        segStart1 = [intersections objectAtIndex:0];
        segStart2 = [intersections objectAtIndex:1];
    } else {
        tool_state = DRAWING_START;
        segEnd1 = [intersections objectAtIndex:0];
        segEnd2 = [intersections objectAtIndex:1];
        _dragging = false;
        [_editViewController.graphicView setNeedsDisplay: TRUE];
    }
    
}

- (void) drawBackground {
	// Draw in the background, concerns the complete view.
}

- (void) drawForegroundForLayer:(GSLayer *)Layer {
//    NSLog(@"start1: %@, %lu, %g", segStart1->path, segStart1->segId, segStart1->t);
//    NSLog(@"start2: %@, %lu, %g", segStart2->path, segStart2->segId, segStart2->t);
//    NSLog(@"end1: %@, %lu, %g", segEnd1->path, segEnd1->segId, segEnd1->t);
//    NSLog(@"end2: %@, %lu, %g", segEnd2->path, segEnd2->segId, segEnd2->t);

    if (segStart1->segId == NSNotFound || segEnd1->segId == NSNotFound ||
        segStart2->segId == NSNotFound || segEnd2->segId == NSNotFound ||
        !segStart1->path || !segStart2->path) {
        if (_dragging) {
            NSBezierPath * path = [NSBezierPath bezierPath];
            [path setLineWidth: 1];
            [path moveToPoint: _draggStart];
            [path lineToPoint: _draggCurrent];
            if (tool_state == DRAWING_START) {
                [[NSColor greenColor] set];
            } else { [[NSColor redColor] set]; }
            [path stroke];
        }
        return;
    }
//    NSLog(@"Drawing!");

    
    int steps = 400;
    CGFloat step1 = ((segEnd1->segId + segEnd1->t) - (segStart1->segId + segStart1->t)) / steps; // XXX
    CGFloat step2 = ((segEnd2->segId + segEnd2->t) - (segStart2->segId + segStart2->t)) / steps;
    long maxLen = 0;
    long minLen = 99999;
    long avgLen = 0;
    SCPathTime* t1 = [segStart1 copy];
    SCPathTime* t2 = [segStart2 copy];
    int actualSteps = 0;
    while ([t1 compareWith: segEnd1] != copysign(1.0, step1)) {
        NSPoint p1 = [t1 point];
        NSPoint p2 = [t2 point];
        long dist = GSSquareDistance(p1,p2);
        if (dist < minLen) minLen = dist;
        if (dist > maxLen) maxLen = dist;
        avgLen += dist;
        [t1 stepTimeBy:step1];
        [t2 stepTimeBy:step2];
        actualSteps++;
    }
    avgLen = avgLen / actualSteps;
    NSLog(@"Min: %li, avg: %li, max: %li. steps=%ul", minLen, avgLen, maxLen, actualSteps);

    t1 = [segStart1 copy];
    t2 = [segStart2 copy];
    while ([t1 compareWith: segEnd1] != copysign(1.0, step1)) {
        NSPoint p1 = [t1 point];
        NSPoint p2 = [t2 point];
        long dist = GSSquareDistance(p1,p2);
        NSBezierPath * path = [NSBezierPath bezierPath];
        CGFloat scale = fabs((CGFloat)maxLen-minLen);
        if (scale < 100) scale = 100;
        CGFloat hue = (120+((avgLen-dist)/scale*120.0))/360;
        if (hue < 0.2) hue -= 0.11;
        NSColor *c = [NSColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:0.7];
//        NSLog(@"Dist: %li, hue: %g. Min: %li, avg: %li, max: %li", dist, hue, minLen, avgLen, maxLen);
        [path setLineWidth: 2];
        [path moveToPoint: p1];
        [path lineToPoint: p2];
        [c set];
        [path stroke];
        [t1 stepTimeBy:step1];
        [t2 stepTimeBy:step2];
    }

    // Draw in the foreground, concerns the complete view.
}

- (void) drawLayer:(GSLayer*)Layer atPoint:(NSPoint)aPoint asActive:(BOOL)Active attributes:(NSDictionary*)Attributes {
	// Draw anythin for this particular layer.
    [ _editViewController.graphicView drawLayerOutlines:Layer aPoint:aPoint color:[NSColor blackColor] fill:!Active];
}

- (void) willActivate {
	// Called when the tool is selected by the user.
	// editViewController.graphicView.cursor = [NSCursor openHandCursor];
    segStart1 = [segStart1 init];
    segStart2 = [segStart2 init];
    segEnd1 = [segEnd1 init];
    segEnd2 = [segEnd2 init];
}

- (void) willDeactivate {}

@end

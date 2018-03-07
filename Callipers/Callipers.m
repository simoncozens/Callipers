//
//  Callipers.m
//  Callipers
//
//  Created by Simon Cozens on 19/12/2015.
//  Copyright © 2015 Simon Cozens. All rights reserved.
//

#import "Callipers.h"
#import <GlyphsCore/GSGeometrieHelper.h>

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
    measure_mode = MEASURE_CLOSEST;
    [NSBundle loadNibNamed:@"CallipersOptions" owner:self];
    [_stepsSlider setTarget:self];
    [_stepsSlider setAction:@selector(redrawTheView)];
    [_thickSlider setTarget:self];
    [_thickSlider setAction:@selector(redrawTheView)];
    
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

- (BOOL) willSelectTempTool:(id) tempTool {	return NO; }

- (void) mouseDown:(NSEvent*)theEvent {
	// Called when the mouse button is clicked.
	_editViewController = [_windowController activeEditViewController];
    currentLayer = [_editViewController.graphicView activeLayer];
	// editViewController.graphicView.cursor = [NSCursor closedHandCursor];
    _draggStart = [_editViewController.graphicView getActiveLocation: theEvent];
    if (tool_state == DRAWING_START) {
//        NSLog(@"Clearing start");
        segStart1 = [segStart1 init];
        segStart2 = [segStart2 init];
    }
//    NSLog(@"Clearing end");
    segEnd1 = [segEnd1 init];
    segEnd2 = [segEnd2 init];
    cacheMin = 0;
//    NSLog(@"Mousedown ended");
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
//        NSLog(@"Setting start");
//        NSLog(@"start1: %@, %lu, %g", segStart1->path, segStart1->segId, segStart1->t);
//        NSLog(@"start2: %@, %lu, %g", segStart2->path, segStart2->segId, segStart2->t);
    } else {
        tool_state = DRAWING_START;
        segEnd1 = [intersections objectAtIndex:0];
        segEnd2 = [intersections objectAtIndex:1];
        _dragging = false;
//        NSLog(@"Setting end");
//        NSLog(@"start1: %@, %lu, %g", segStart1->path, segStart1->segId, segStart1->t);
//        NSLog(@"start2: %@, %lu, %g", segStart2->path, segStart2->segId, segStart2->t);
//        NSLog(@"end1: %@, %lu, %g", segEnd1->path, segEnd1->segId, segEnd1->t);
//        NSLog(@"end2: %@, %lu, %g", segEnd2->path, segEnd2->segId, segEnd2->t);
        [_editViewController.graphicView setNeedsDisplay: TRUE];
    }
    
}

- (void) redrawTheView {
    [_editViewController.graphicView setNeedsDisplay: TRUE];
}

- (void) drawBackground {
	// Draw in the background, concerns the complete view.
}

- (NSPoint) minSquareDistancePoint:(NSPoint) p Curve:(SCPathTime*)c {
    NSPoint best = [c point];
    if (measure_mode == MEASURE_CORRESPONDING) return best;
    
    long bestDist = GSSquareDistance(p, best);
    SCPathTime* c2 = [c copy];
    while (true){
        [c2 stepTimeBy:0.01];
        NSPoint p2 = [c2 point];
        long d = GSSquareDistance(p, p2);
        if (d < bestDist) {
            bestDist = d;
            best = p2;
        }
        if (d > bestDist) break;
    }
    c2 = [c copy];
    while (true){
        [c2 stepTimeBy:-0.01];
        NSPoint p2 = [c2 point];
        long d = GSSquareDistance(p, p2);
        if (d < bestDist) {
            bestDist = d;
            best = p2;
        }
        if (d > bestDist) break;
    }
    return best;
}

- (CGFloat) segLength: (GSPath*)p segId:(NSInteger)segId from:(CGFloat)t1 to:(CGFloat)t2 {
    NSArray* seg = p.segments[segId];
    if ([ seg count] == 2) {
        NSPoint start = [[seg objectAtIndex:0] pointValue];
        NSPoint end = [[seg objectAtIndex:1] pointValue];
        CGFloat x1 = start.x + (end.x-start.x)*fmod(t1,1.0);
        CGFloat y1 = start.y + (end.y-start.y)*fmod(t1,1.0);
        CGFloat x2 = start.x + (end.x-start.x)*fmod(t2,1.0);
        CGFloat y2 = start.y + (end.y-start.y)*fmod(t2,1.0);
        return sqrtf( (float)(((x1 - x2) * (x1 - x2)) + ((y1 - y2) * (y1 - y2))));
    } else {
        NSPoint o1, o2, o3, o4;
        NSPoint i1 = [[seg objectAtIndex:0] pointValue];
        NSPoint i2 = [[seg objectAtIndex:1] pointValue];
        NSPoint i3 = [[seg objectAtIndex:2] pointValue];
        NSPoint i4 = [[seg objectAtIndex:3] pointValue];
        GSSegmentBetweenPoints(i1,i2,i3,i4, &o1, &o2, &o3, &o4, GSPointAtTime(i1,i2,i3,i4,t1),GSPointAtTime(i1,i2,i3,i4,t2));
        return GSLengthOfSegment(o1,o2,o3,o4);
    }
}

- (CGFloat) pathLength: (SCPathTime*)start to: (SCPathTime*) end {
    SCPathTime *p1, *p2;
    if (start->segId > end->segId || (start->segId == end->segId && start->t > end->t)) {
        p1 = end; p2 = start;
    } else {
        p1 = start; p2 = end;
    }
    NSInteger segId = p1->segId;
    CGFloat total = 0;
    CGFloat t = p1->t;
    while (segId < p2->segId) {
        total += [self segLength: p1->path segId:segId from:t to:1];
        segId++;
        t = 0;
    }
    total += [self segLength:p1->path segId:segId from:t to:p2->t];
    return total;
}


- (void) drawForegroundForLayer:(GSLayer *)Layer {

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

    // Measure the two paths. Swap if needed
    CGFloat sl1 = [self pathLength:segStart1 to:segEnd1];
    CGFloat sl2 = [self pathLength:segStart2 to:segEnd2];
//    NSLog(@"Length of intersections, 1: %g, 2: %g", sl1, sl2);
    if (sl1 < sl2) {
        SCPathTime* ss = segStart2;
        SCPathTime* se = segEnd2;
        segStart2 = segStart1; segStart1 = ss;
        segEnd2 = segEnd1; segEnd1 = se;
    }

    int steps = [_stepsSlider intValue];
    CGFloat step1 = ((segEnd1->segId + segEnd1->t) - (segStart1->segId + segStart1->t)) / steps; // XXX
    CGFloat step2 = ((segEnd2->segId + segEnd2->t) - (segStart2->segId + segStart2->t)) / steps;
    long maxLen, minLen, avgLen;
    SCPathTime* t1, *t2;

    if (cacheMin == 0) {
        minLen = 99999;
        maxLen = 0;
        avgLen = 0;
        t1 = [segStart1 copy];
        t2 = [segStart2 copy];
        int actualSteps = 0;
        while ([t1 compareWith: segEnd1] != copysign(1.0, step1)) {
            NSPoint p1 = [t1 point];
            NSPoint p2 = [self minSquareDistancePoint:p1 Curve:t2];
            long dist = GSSquareDistance(p1,p2);
            if (dist < minLen) minLen = dist;
            if (dist > maxLen) maxLen = dist;
            avgLen += dist;
            [t1 stepTimeBy:step1];
            [t2 stepTimeBy:step2];
            actualSteps++;
        }
        cacheAvg = avgLen = avgLen / actualSteps;
        cacheMin = minLen;
        cacheMax = maxLen;
    } else {
        maxLen = cacheMax;
        minLen = cacheMin;
        avgLen = cacheAvg;
    }

    t1 = [segStart1 copy];
    t2 = [segStart2 copy];
    while ([t1 compareWith: segEnd1] != copysign(1.0, step1)) {
        NSPoint p1 = [t1 point];
        NSPoint p2 = [self minSquareDistancePoint:p1 Curve:t2];
        long dist = GSSquareDistance(p1,p2);
        NSBezierPath * path = [NSBezierPath bezierPath];
        CGFloat scale = fabs((CGFloat)maxLen-minLen);
        if (scale < 100) scale = 100;
        CGFloat hue = (120+((avgLen-dist)/scale*120.0))/360;
//        if (hue < 0.2) hue -= 0.11;
        NSColor *c = [NSColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1];
//        NSLog(@"Dist: %li, hue: %g. Min: %li, avg: %li, max: %li", dist, hue, minLen, avgLen, maxLen);
        [path setLineWidth: [_thickSlider intValue]];
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
//    NSLog(@"Willactivate called");
    [_optionsWindow makeKeyAndOrderFront:self];
    GSLayer* layer = [_editViewController.graphicView activeLayer];
    if (layer != currentLayer) {
        segStart1 = [segStart1 init];
        segStart2 = [segStart2 init];
        segEnd1 = [segEnd1 init];
        segEnd2 = [segEnd2 init];
    }
}

- (IBAction) changeMeasureMode:(NSButton*)sender {
    if ([sender tag] == 1) { measure_mode = MEASURE_CLOSEST; }
    else if ([sender tag] == 2) { measure_mode = MEASURE_CORRESPONDING; }
    [self redrawTheView];
}

- (void) willDeactivate {
	 [_optionsWindow orderOut:self];
}

@end

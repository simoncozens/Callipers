//
//  Callipers.h
//  Callipers
//
//  Created by Simon Cozens on 19/12/2015.
//  Copyright © 2015 Simon Cozens. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GlyphsCore/GlyphsToolDrawProtocol.h>
#import <GlyphsCore/GlyphsToolEventProtocol.h>
#import <GlyphsCore/GSToolSelect.h>
#import <GlyphsCore/GSLayer.h>
#import <GlyphsCore/GSPath.h>
#import <GlyphsCore/GSNode.h>
#import <GlyphsCore/GSGeometrieHelper.h>

#import "SCPathTime.h"

typedef enum {
    DRAWING_START,
    DRAWING_END
} TOOL_STATE ;

typedef enum {
    MEASURE_CLOSEST,
    MEASURE_CORRESPONDING
} MEASURE_MODE ;

@interface Callipers : GSToolSelect {
    SCPathTime* segStart1;
    SCPathTime* segStart2;
    SCPathTime* segEnd1;
    SCPathTime* segEnd2;
    long cacheMin;
    long cacheMax;
    long cacheAvg;
    TOOL_STATE tool_state;
    MEASURE_MODE measure_mode;
    GSLayer* currentLayer;
}

- (IBAction) changeMeasureMode:(id)sender;

@property (nonatomic, weak) IBOutlet NSWindow *optionsWindow;
@property (weak) IBOutlet NSSlider *stepsSlider;
@property (weak) IBOutlet NSSlider *thickSlider;

@end

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
#import <GlyphsCore/GlyphsPathPlugin.h>
#import <GlyphsCore/GSLayer.h>
#import <GlyphsCore/GSPath.h>
#import <GlyphsCore/GSNode.h>
#import <GlyphsCore/GSGeometrieHelper.h>

#import "SCPathTime.h"

typedef enum {
    DRAWING_START,
    DRAWING_END
} TOOL_STATE ;

@interface Callipers : GlyphsPathPlugin {
    SCPathTime* segStart1;
    SCPathTime* segStart2;
    SCPathTime* segEnd1;
    SCPathTime* segEnd2;
    long cacheMin;
    long cacheMax;
    long cacheAvg;
    TOOL_STATE tool_state;
}

@end

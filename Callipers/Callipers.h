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


typedef struct myPathTime  {
    NSInteger segId;
    CGFloat t;
} myPathTime;


@interface Callipers : GlyphsPathPlugin {
    myPathTime segStart1, segStart2, segEnd1,segEnd2;
    
    /* Ideally these paths would go into the pathtime structs, but you can't
       put a ObjC object inside a C struct. */
    GSPath* path1;
    GSPath* path2;
}

@end

#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#endif

#import "CGContextShim.h"

// https://github.com/gnachman/iTerm2/blob/b7d3fc6d9372a083ffadc2effbba01b67c040a69/sources/iTermGraphicsUtilities.m#L23

// if (useThinStrokes) {
//     CGContextSetShouldSmoothFonts(ctx, YES);
//     // This seems to be available at least on 10.8 and later. The only reference to it is in
//     // WebKit. This causes text to render just a little lighter, which looks nicer.
//     savedFontSmoothingStyle = CGContextGetFontSmoothingStyle(ctx);
//     CGContextSetFontSmoothingStyle(ctx, 16);
// }


#ifdef USE_FONT_SMOOTHING_STYLE
// The use of non-public or deprecated APIs is not permitted on the App Store

extern void CGContextSetFontSmoothingStyle(CGContextRef, int);
extern int CGContextGetFontSmoothingStyle(CGContextRef);

void STContextSetFontSmoothingStyle(CGContextRef context, int style) {
    CGContextSetFontSmoothingStyle(context, style);
}

int STContextGetFontSmoothingStyle(CGContextRef context) {
    return CGContextGetFontSmoothingStyle(context);
}
#endif

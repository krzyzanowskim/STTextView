#ifndef CGContextShim_h
#define CGContextShim_h

#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#endif

#ifdef USE_FONT_SMOOTHING_STYLE
void STContextSetFontSmoothingStyle(CGContextRef context, int style);
int STContextGetFontSmoothingStyle(CGContextRef context);
#endif

#endif /* CGContextShim_h */

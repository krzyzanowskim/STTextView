#ifndef CGContextShim_h
#define CGContextShim_h

#import <Cocoa/Cocoa.h>

#ifdef USE_FONT_SMOOTHING_STYLE
void STContextSetFontSmoothingStyle(CGContextRef context, int style);
int STContextGetFontSmoothingStyle(CGContextRef context);
#endif

#endif /* CGContextShim_h */

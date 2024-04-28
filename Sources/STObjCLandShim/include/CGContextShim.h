#ifndef CGContextShim_h
#define CGContextShim_h

#import <Cocoa/Cocoa.h>

void STContextSetFontSmoothingStyle(CGContextRef context, int style);
int STContextGetFontSmoothingStyle(CGContextRef context);

#endif /* CGContextShim_h */

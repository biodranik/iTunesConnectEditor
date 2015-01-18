/****************************************************************************
 The MIT License (MIT)

 Copyright (c) 2013 Alexander Zolotarev (me@alex.bio) from Minsk, Belarus.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#import <Cocoa/Cocoa.h>

@interface ImageViewWithPath : NSImageView
// Stores path for displayed image and automatically reloads image after changing it
// Resets image with nil path
@property (copy, nonatomic) NSString * path;
@end

@interface DragDestinationWindow : NSWindow <NSDraggingDestination>

// @returns paths to iPhone4 Screenshots or nil if they're absent
- (NSArray *)iPhone4ScreenshotsOrNil;
@property (weak) IBOutlet ImageViewWithPath * iPhone4_1;
@property (weak) IBOutlet ImageViewWithPath * iPhone4_2;
@property (weak) IBOutlet ImageViewWithPath * iPhone4_3;
@property (weak) IBOutlet ImageViewWithPath * iPhone4_4;
@property (weak) IBOutlet ImageViewWithPath * iPhone4_5;

// @returns paths to iPhone5 Screenshots or nil if they're absent
- (NSArray *)iPhone5ScreenshotsOrNil;
@property (weak) IBOutlet ImageViewWithPath * iPhone5_1;
@property (weak) IBOutlet ImageViewWithPath * iPhone5_2;
@property (weak) IBOutlet ImageViewWithPath * iPhone5_3;
@property (weak) IBOutlet ImageViewWithPath * iPhone5_4;
@property (weak) IBOutlet ImageViewWithPath * iPhone5_5;

// @returns paths to iPad Screenshots or nil if they're absent
- (NSArray *)iPadScreenshotsOrNil;
@property (weak) IBOutlet ImageViewWithPath * iPad_1;
@property (weak) IBOutlet ImageViewWithPath * iPad_2;
@property (weak) IBOutlet ImageViewWithPath * iPad_3;
@property (weak) IBOutlet ImageViewWithPath * iPad_4;
@property (weak) IBOutlet ImageViewWithPath * iPad_5;

// Caches urls dragged into window for faster processing
@property (strong) NSArray * draggedUrls;

- (void)setIPhone4Screenshots:(NSArray *)sshots;
- (void)setIPhone5Screenshots:(NSArray *)sshots;
- (void)setIPadScreenshots:(NSArray *)sshots;

@end

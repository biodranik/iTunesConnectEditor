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

#import "CharsCounterDelegate.h"

@implementation CharsCounterDelegate

- (id)initWithLabel:(NSTextField *)label maxLen:(NSInteger)len
{
  if ((self = [super init]))
  {
    _label = label;
    _maxLen = len;
    [self updateCount:0];
  }
  return self;
}

- (void)updateCount:(NSInteger)newCount
{
  _label.stringValue = [NSString stringWithFormat:@"%ld/%ld", (long)newCount, (long)_maxLen];
}

// Sent by NSTextView
- (void)textDidChange:(NSNotification *)aNotification
{
  NSTextView * v = aNotification.object;
  [self updateCount:v.string.length];
}

// Sent by NSTextFiend and it's descendants
- (void)controlTextDidChange:(NSNotification *)aNotification
{
  NSTextField * v = aNotification.object;
  [self updateCount:v.stringValue.length];
}

@end

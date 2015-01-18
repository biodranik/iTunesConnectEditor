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

#import <Foundation/Foundation.h>

@interface XMLProcessor : NSObject

@property (strong) NSXMLDocument * xmlDoc;
// Stores path to original xml file, also used to copy screenshots
@property (strong) NSString * pathToXml;

- (BOOL)loadFromFile:(NSString *)file;
// Saves current XML DOM tree to the original file
- (void)overwrite;

// @returns list of all existing localizations
@property (readonly) NSArray * locales;
@property (readonly) NSString * version;

- (NSString *)titleForLanguage:(NSString *)lang;
- (BOOL)setTitle:(NSString *)title forLanguage:(NSString *)lang;

- (NSString *)descriptionForLanguage:(NSString *)lang;
- (BOOL)setDescription:(NSString *)description forLanguage:(NSString *)lang;

- (NSString *)whatsNewForLanguage:(NSString *)lang;
- (BOOL)setWhatsNew:(NSString *)whatsNew forLanguage:(NSString *)lang;

// Keywords are delimeted by commas
- (NSString *)keywordsForLanguage:(NSString *)lang;
- (BOOL)setKeywords:(NSString *)keywords forLanguage:(NSString *)lang;

- (NSString *)supportUrlForLanguage:(NSString *)lang;
- (BOOL)setSupportUrl:(NSString *)url forLanguage:(NSString *)lang;

- (NSString *)marketingUrlForLanguage:(NSString *)lang;
- (BOOL)setMarketingUrl:(NSString *)url forLanguage:(NSString *)lang;

- (NSString *)privacyPolicyUrlForLanguage:(NSString *)lang;
- (BOOL)setPrivacyPolicyUrl:(NSString *)url forLanguage:(NSString *)lang;

// @returns ScreenShot objects for present screenshots or empty array
- (NSArray *)iPhone4ScreenshotsforLanguage:(NSString *)lang;
- (BOOL)setIPhone4Screenshots:(NSArray *)files forLanguage:(NSString *)lang;

- (NSArray *)iPhone5ScreenshotsforLanguage:(NSString *)lang;
- (BOOL)setIPhone5Screenshots:(NSArray *)files forLanguage:(NSString *)lang;

- (NSArray *)iPadScreenshotsforLanguage:(NSString *)language;
- (BOOL)setIPadScreenshots:(NSArray *)files forLanguage:(NSString *)lang;

@end

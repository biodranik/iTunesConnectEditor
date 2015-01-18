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

#import "AppDelegate.h"
#import "CharsCounterDelegate.h"


@interface AppDelegate ()
@property (strong) IBOutlet DragDestinationWindow * window;
@property (strong) IBOutlet NSTableView * languageTable;
@property (strong) LocalizationTable * tableDelegate;

@property (strong) CharsCounterDelegate * keywordsCounterDelegate;
@property (strong) IBOutlet NSTextField * keywordsCounter;
@property (strong) CharsCounterDelegate * descriptionCounterDelegate;
@property (strong) IBOutlet NSTextField * descriptionCounter;
@property (strong) CharsCounterDelegate * whatsNewCounterDelegate;
@property (strong) IBOutlet NSTextField * whatsNewCounter;

@property (strong) IBOutlet NSTextField * login;
@property (strong) IBOutlet NSTextField * password;
@property (strong) IBOutlet NSTextField * appSKU;
@property (strong) IBOutlet NSTextField * appTitle;
@property (strong) IBOutlet NSTextField * appSupportUrl;
@property (strong) IBOutlet NSTextField * appMarketingUrl;
@property (strong) IBOutlet NSTextField * appPrivacyPolicyUrl;
@property (strong) IBOutlet NSTokenField * appKeywords;
@property (strong) IBOutlet NSTextView * appDescription;
@property (strong) IBOutlet NSTextView * appWhatsNew;

- (IBAction)onFetch:(id)sender;
- (IBAction)onUpload:(id)sender;
@end

@implementation AppDelegate

// Helpers to change char counters on text change
- (void)loadKeywords:(NSString *)text
{
  _appKeywords.stringValue = text;
  [_keywordsCounterDelegate updateCount:text.length];
}
- (void)loadDescription:(NSString *)text
{
  _appDescription.string = text;
  [_descriptionCounterDelegate updateCount:text.length];
}
- (void)loadWhatsNew:(NSString *)text
{
  _appWhatsNew.string = text;
  [_whatsNewCounterDelegate updateCount:text.length];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  self.transporter = [[Transporter alloc] init];
  self.xmlProcessor = [[XMLProcessor alloc] init];
  self.tableDelegate = [[LocalizationTable alloc] initWithTableView:self.languageTable delegate:self];

  _appKeywords.delegate = self.keywordsCounterDelegate = [[CharsCounterDelegate alloc] initWithLabel:_keywordsCounter maxLen:100];
  _appDescription.delegate = self.descriptionCounterDelegate = [[CharsCounterDelegate alloc] initWithLabel:_descriptionCounter maxLen:4000];
  _appWhatsNew.delegate = self.whatsNewCounterDelegate = [[CharsCounterDelegate alloc] initWithLabel:_whatsNewCounter maxLen:4000];

  [_window registerForDraggedTypes:@[NSURLPboardType]];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
  return YES;
}

- (BOOL)checkLoginPass
{
  if (!_login.stringValue.length)
  {
    NSLog(@"ERROR: Login is empty");
    return NO;
  }
  if (!_password.stringValue.length)
  {
    NSLog(@"ERROR: Password is empty");
    return NO;
  }
  return YES;
}

- (BOOL)checkSKU
{
  if (!_appSKU.stringValue.length)
  {
    NSLog(@"ERROR: Application SKU is empty");
    return NO;
  }
  return YES;
}

- (NSString *)currentLanguage
{
  return _tableDelegate.activeLanguage;
}

// *********************** Button Handlers ***********************************************************

- (IBAction)onFetch:(id)sender
{
  if (![self checkLoginPass] || ![self checkSKU])
    return;

  self.currentAppFolder = [[NSTemporaryDirectory() stringByAppendingPathComponent:
                          [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]]
                          stringByAppendingPathComponent:self.appSKU.stringValue];
  NSLog(@"INFO: Metadata directory: %@", _currentAppFolder);

  if (![_transporter fetchMetaDataWithLogin:_login.stringValue
                                   password:_password.stringValue
                                   vendorId:_appSKU.stringValue
                            destinationPath:_currentAppFolder])
    return;

  [_xmlProcessor loadFromFile:[_currentAppFolder stringByAppendingPathComponent:
                               [NSString stringWithFormat:@"%@.itmsp/metadata.xml", _appSKU.stringValue]]];
  self.tableDelegate.locales = _xmlProcessor.locales;

  // Choose en-US if it's present as default, or the first lang otherwise
  NSString * choosenLang = nil;
  for (NSString * lang in _xmlProcessor.locales)
  {
    if ([lang isEqualToString:@"en-US"])
    {
      choosenLang = lang;
      break;
    }
  }
  if (!choosenLang)
    choosenLang = [_xmlProcessor.locales objectAtIndex:0];
  _tableDelegate.activeLanguage = choosenLang;
  [self loadLanguage:choosenLang];
}

- (IBAction)onUpload:(id)sender
{
  [self saveEditsForLanguage:self.currentLanguage];

  if (![self checkLoginPass])
    return;

  // @TODO launch asynchronously

  // Validate modified metadata with screenshots
  if (![_transporter verifyMetaDataWithLogin:_login.stringValue
                                    password:_password.stringValue
                        existingMetadataPath:_currentAppFolder])
    return;

  // Upload it, if everything is ok
  if (![_transporter uploadMetaDataWithLogin:_login.stringValue
                                    password:_password.stringValue
                        existingMetadataPath:_currentAppFolder])
    return;
}

- (void)saveEditsForLanguage:(NSString *)lang
{
  // Screenshots should be already saved (after drag), right?

//  NSArray * iPadScreenshots = [_window iPadScreenshotsOrNil];
//  if (iPadScreenshots)
//  {
//    if (![_xmlProcessor setIPadScreenshots:iPadScreenshots forLanguage:lang])
//      return;
//  }
//  else
//    NSLog(@"WARNING: iPad screenshots will not be updated");
//
//  NSArray * iPhone4Screenshots = [_window iPhone4ScreenshotsOrNil];
//  if (iPhone4Screenshots)
//  {
//    if (![_xmlProcessor setIPhone4Screenshots:iPhone4Screenshots forLanguage:lang])
//      return;
//  }
//  else
//    NSLog(@"WARNING: iPhone4 screenshots will not be updated");
//
//  NSArray * iPhone5Screenshots = [_window iPhone5ScreenshotsOrNil];
//  if (iPhone5Screenshots)
//  {
//    if (![_xmlProcessor setIPhone5Screenshots:iPhone5Screenshots forLanguage:lang])
//      return;
//  }
//  else
//    NSLog(@"WARNING: iPhone5 screenshots will not be updated");

  if (![_xmlProcessor setTitle:_appTitle.stringValue forLanguage:lang])
    NSLog(@"ERROR: title for %@ can't be updated", lang);

  if (![_xmlProcessor setDescription:_appDescription.string forLanguage:lang])
    NSLog(@"ERROR: description for %@ can't be updated", lang);

  // @TODO What's new is optional for new apps
  if (_appWhatsNew.string.length)
    if (![_xmlProcessor setWhatsNew:_appWhatsNew.string forLanguage:lang])
      NSLog(@"ERROR: what's new for %@ can't be updated", lang);

  if (![_xmlProcessor setKeywords:_appKeywords.stringValue forLanguage:lang])
    NSLog(@"ERROR: keywords for %@ can't be updated", lang);

  if (![_xmlProcessor setSupportUrl:_appSupportUrl.stringValue forLanguage:lang])
    NSLog(@"ERROR: support url for %@ can't be updated", lang);

  if (![_xmlProcessor setMarketingUrl:_appMarketingUrl.stringValue forLanguage:lang])
    NSLog(@"ERROR: marketing url for %@ can't be updated", lang);

  if (![_xmlProcessor setPrivacyPolicyUrl:_appPrivacyPolicyUrl.stringValue forLanguage:lang])
    NSLog(@"ERROR: privacy policy url for %@ can't be updated", lang);

  // Save changes
  [_xmlProcessor overwrite];
}

- (void)loadLanguage:(NSString *)langCode
{
  _appTitle.stringValue = [_xmlProcessor titleForLanguage:langCode];
  [self loadDescription:[_xmlProcessor descriptionForLanguage:langCode]];
  [self loadWhatsNew:[_xmlProcessor whatsNewForLanguage:langCode]];
  [self loadKeywords:[_xmlProcessor keywordsForLanguage:langCode]];
  self.appSupportUrl.stringValue = [_xmlProcessor supportUrlForLanguage:langCode];
  self.appMarketingUrl.stringValue = [_xmlProcessor marketingUrlForLanguage:langCode];
  self.appPrivacyPolicyUrl.stringValue = [_xmlProcessor privacyPolicyUrlForLanguage:langCode];

  // Init screenshots
  [_window setIPhone4Screenshots:[_xmlProcessor iPhone4ScreenshotsforLanguage:langCode]];
  [_window setIPhone5Screenshots:[_xmlProcessor iPhone5ScreenshotsforLanguage:langCode]];
  [_window setIPadScreenshots:[_xmlProcessor iPadScreenshotsforLanguage:langCode]];
}

- (void)onLanguageChangedTo:(NSString *)langCode from:(NSString *)oldLangCode
{
  [self saveEditsForLanguage:oldLangCode];

  [self loadLanguage:langCode];
}

@end

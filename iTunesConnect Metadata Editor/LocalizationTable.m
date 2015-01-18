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

#import "LocalizationTable.h"

// Locale codes are taken from 5.1 spec
// In the real life iTunesConnect returns xx-XX codes for every language
// <lang name>, <5.1 spec recommended>, <real life>
NSString * g_langs[][3] = {
  {@"Chinese (Simplified)", @"cmn-Hans", @"cmn-Hans"},
  {@"Chinese (Traditional)", @"cmn-Hant", @"cmn-Hant"},
  {@"Danish", @"da", @"da-DK"},
  {@"Dutch", @"nl", @"nl-NL"},
  {@"English (Australia)", @"en-AU", @"en-AU"},
  {@"English (Canada)", @"en-CA", @"en-CA"},
  {@"English (UK)", @"en-GB", @"en-GB"},
  {@"English (United States)", @"en-US", @"en-US"},
  {@"Finnish", @"fi", @"fi-FI"},
  {@"French (Canada)", @"fr-CA", @"fr-CA"},
  {@"French (France)", @"fr-FR", @"fr-FR"},
  {@"German", @"de", @"de-DE"},
  {@"Greek", @"el", @"el-GR"},
  {@"Indonesian", @"id", @"id-ID"},
  {@"Italian", @"it", @"it-IT"},
  {@"Japanese", @"ja", @"ja-JP"},
  {@"Korean", @"ko", @"ko-KR"},
  {@"Malay", @"ms", @"ms-MY"},
  {@"Norwegian", @"no", @"no-NO"},
  {@"Portuguese (Brazil)", @"pt-BR", @"pt-BR"},
  {@"Portuguese (Portugal)", @"pt-PT", @"pt-PT"},
  {@"Russian", @"ru", @"ru-RU"},
  {@"Spanish (Mexico)", @"es-MX", @"es-MX"},
  {@"Spanish (Spain)", @"es-ES", @"es-ES"},
  {@"Swedish", @"sv", @"sv-SE"},
  {@"Thai", @"th", @"th-TH"},
  {@"Turkish", @"tr", @"tr-TR"},
  {@"Vietnamese", @"vi", @"vi-VI"}
};

//NSString * alternateLanguageCode(NSString * code)
//{
//  for (NSInteger i = 0; i < sizeof(g_langs)/sizeof(g_langs[0]); ++i)
//  {
//    if ([code isEqualToString:g_langs[i][1]])
//      return g_langs[i][2];
//    if ([code isEqualToString:g_langs[i][2]])
//      return g_langs[i][1];
//  }
//  NSLog(@"ERROR: Unsupported language code: %@", code);
//  return code;
//}

@interface LocalizationTable()
@property (weak) NSTableView * table;
@property (weak) id<LanguageChanged> delegate;
@end

@implementation LocalizationTable

- (id)initWithTableView:(NSTableView *)aTable delegate:(id<LanguageChanged>)d
{
  if ((self = [super init]))
  {
    aTable.delegate = self;
    aTable.dataSource = self;
    self.table = aTable;
    self.delegate = d;
  }
  return self;
}

- (void)setActiveLanguage:(NSString *)aActiveLanguage
{
  _activeLanguage = aActiveLanguage;
  [_table reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
  return _locales.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
  NSTextFieldCell * cell = [[NSTextFieldCell alloc] init];

  for (NSInteger i = 0; i < sizeof(g_langs)/sizeof(g_langs[0]); ++i)
  {
    NSString * lang = [_locales objectAtIndex:rowIndex];
    if ([lang isEqualToString:g_langs[i][1]] || [lang isEqualToString:g_langs[i][2]])
    {
      cell.stringValue = g_langs[i][0];
      // trick to quickly associate language code
      cell.tag = i;
      // Select row if necessary
      if ([_activeLanguage isEqualToString:lang])
        [aTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
      break;
    }
  }
  return cell;
}

//- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
//{
//  NSString * oldLang = _activeLanguage;
//  NSString * newLang = [_locales objectAtIndex:_table.selectedRow];
//  [_delegate onLanguageChanged:newLang];
//}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
  NSString * oldLang = _activeLanguage;
  _activeLanguage = [_locales objectAtIndex:rowIndex];
  [_delegate onLanguageChangedTo:_activeLanguage from:oldLang];
  return YES;
}

@end

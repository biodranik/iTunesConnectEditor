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

#import "XMLProcessor.h"
#import "LocalizationTable.h"
#import "ScreenShot.h"
#import "Globals.h"

@implementation XMLProcessor

- (BOOL)loadFromFile:(NSString *)file
{
  self.xmlDoc = nil;
  self.pathToXml = nil;

  NSError * err = nil;

  NSURL * fUrl = [NSURL fileURLWithPath:file];
  if (!fUrl)
  {
    NSLog(@"Can't create an URL from file %@.", file);
    return NO;
  }

  NSXMLDocument * xml = [[NSXMLDocument alloc] initWithContentsOfURL:fUrl
                                                             options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)
                                                               error:&err];
  if (xml == nil)
    xml = [[NSXMLDocument alloc] initWithContentsOfURL:fUrl
                                               options:NSXMLDocumentTidyXML
                                                 error:&err];
  if (xml == nil)
  {
    if (err)
      NSLog(@"Can't load XML file %@, reason: %@", file, err.localizedDescription);
    return NO;
  }
  if (err)
    NSLog(@"Loaded XML file %@, but with errors: %@", file, err.localizedDescription);

  self.xmlDoc = xml;
  self.pathToXml = file;

  // @TODO Add two versions support according to the spec: "live" and "in-flight"
  // Now we temporarily remove "live" version info completely if it exists
  NSArray * versions = [self execXPath:@"/package/software/software_metadata/versions/version"];
  if (versions.count == 2)
  {
    NSXMLElement * v1 = [versions objectAtIndex:0];
    NSXMLElement * v2 = [versions objectAtIndex:1];
    NSXMLNode * v1Attr = [v1.attributes objectAtIndex:0];
    NSXMLNode * v2Attr = [v2.attributes objectAtIndex:0];
    NSString * v1Ver = v1Attr.stringValue;
    NSString * v2Ver = v2Attr.stringValue;

    NSLog(@"WARNING: Found 2 versions: %@ and %@.", v1Ver, v2Ver);

    if ([v1Ver compare:v2Ver] == NSOrderedAscending)
    {
      NSLog(@"Temporarily removing version %@", v1Ver);
      [v1 detach];
    }
    else
    {
      NSLog(@"Temporarily removing version %@", v2Ver);
      [v2 detach];
    }
  }

  return YES;
}

- (BOOL)saveToFile:(NSString *)filePath
{
  if (!_xmlDoc)
  {
    NSLog(@"ERROR: XML not loaded to save it in file %@", filePath);
    return NO;
  }
  NSData * xmlData = [_xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
  if (![xmlData writeToFile:filePath atomically:YES])
  {
    NSLog(@"ERROR while saving XML to file %@", filePath);
    return NO;
  }
  return YES;
}

- (void)overwrite
{
  // @TODO check error?
  [self saveToFile:_pathToXml];
}

- (NSArray *)execXPath:(NSString *)xPath
{
  if (!_xmlDoc)
  {
    NSLog(@"ERROR: XML wasn't loaded before query %@", xPath);
    return nil;
  }

  NSError * err = nil;
  NSArray * nodes = [_xmlDoc nodesForXPath:xPath error:&err];

  if (err != nil)
    NSLog(@"ERROR %@ while executing xPath %@", err.localizedDescription, xPath);

  if (nodes.count)
    return nodes;

  return nil;
}

///////////////////////////////////////////////////////////////
- (NSArray *)locales
{
  NSArray * elements = [self execXPath:@"/package/software/software_metadata/versions/version/locales/locale"];
  if (elements)
  {
    NSMutableArray * languageCodes = [[NSMutableArray alloc] initWithCapacity:elements.count];
    for (NSXMLElement * element in elements)
    {
      NSXMLNode * attr = [element.attributes objectAtIndex:0];
      [languageCodes addObject:attr.stringValue];
    }
    return languageCodes;
  }
  NSLog(@"WARNING: No localizations are present in XML");
  return nil;
}

- (NSString *)version
{
  NSArray * versions = [self execXPath:@"/package/software/software_metadata/versions/version/@string"];
  if (versions)
  {
    // @TODO Support two versions, "live" and "in-flight"
    if (versions.count > 1)
      NSLog(@"WARNING: More than one version is not supported at the moment");

    NSXMLNode * el = [versions objectAtIndex:0];
    assert(el.kind == NSXMLAttributeKind);
    return el.stringValue;
  }
  return @"";
}

//- (void)setVersion:(NSString *)version
//{
//  NSArray * versions = [self execXPath:@"/package/software/software_metadata/versions/version/@string"];
//  if (versions)
//  {
//    // @TODO Support two versions, "live" and "in-flight"
//    if (versions.count > 1)
//      NSLog(@"WARNING: More than one version is not supported at the moment");
//
//    NSXMLNode * el = [versions objectAtIndex:0];
//    assert(el.kind == NSXMLAttributeKind);
//    el.stringValue = version;
//  }
//}

//- (NSDictionary *)titles
//{
//  NSArray * allTitles = [self execXPath:@"/package/software/software_metadata/versions/version/locales/locale/title"];
//  assert(allTitles);
//  NSMutableDictionary * dict = [[NSMutableDictionary alloc] initWithCapacity:allTitles.count];
//  for (NSXMLNode * el in allTitles)
//  {
//    assert(el.parent.kind == NSXMLElementKind);
//    NSXMLElement * locale = (NSXMLElement *)el.parent;
//    NSXMLElement * attr = [locale.attributes objectAtIndex:0];
//    [dict setObject:el.stringValue forKey:attr.stringValue];
//  }
//  return dict;
//}
//
//- (void)setTitles:(NSDictionary *)titles
//{
//}

#define SSHOT_BASE_QUERY @"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/software_screenshots/software_screenshot[@display_target=\"%@\"]"

- (NSArray *)getScreenshots:(NSString *)device forLanguage:(NSString *)language
{
  NSString * query = [NSString stringWithFormat:SSHOT_BASE_QUERY, language, device];
  NSArray * shots = [self execXPath:query];
  if (shots)
  {
    NSMutableArray * resShots = [[NSMutableArray alloc] initWithCapacity:shots.count];
    for (NSXMLNode * parentNode in shots)
    {
      ScreenShot * shot = [[ScreenShot alloc] init];
      for (NSXMLElement * el in parentNode.children)
      {
        if ([el.name isEqualToString:@"file_name"])
          shot.name = el.stringValue;
        if ([el.name isEqualToString:@"size"])
          shot.size = el.stringValue.integerValue;
        if ([el.name isEqualToString:@"checksum"])
          shot.md5 = el.stringValue;
      }
      assert(shot.name);
      assert(shot.size);
      assert(shot.md5);
      [resShots addObject:shot];
    }
    return resShots;
  }
  return @[];
}

- (NSArray *)iPhone4ScreenshotsforLanguage:(NSString *)language
{
  return [self getScreenshots:@"iOS-3.5-in" forLanguage:language];
}

- (NSArray *)iPhone5ScreenshotsforLanguage:(NSString *)language
{
  return [self getScreenshots:@"iOS-4-in" forLanguage:language];
}

- (NSArray *)iPadScreenshotsforLanguage:(NSString *)language
{
  return [self getScreenshots:@"iOS-iPad" forLanguage:language];
}

// Internal helper function
- (BOOL)setScreenshots:(NSArray *)files forDevice:(NSString *)device forLanguage:(NSString *)language
{
  // Validity and resolution of passed files should be checked in UI
  if (!files.count)
  {
    NSLog(@"ERROR: no screenshot files passed");
    return NO;
  }
  if (files.count > 5)
  {
    NSLog(@"WARNING: too many screenshots are passed: %ld", files.count);
    return NO;
  }

  // @TODO create language if it doesn't exist
  // @TODO check that language param short or long form, now we assume
  // that it comes from calling .localizations property and exactly matches the one in XML
  NSString * query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/software_screenshots/software_screenshot[@display_target=\"%@\"]", language, device];
  NSArray * existingSShotsNodes = [self execXPath:query];
  // remove existing screenshots
  for (NSXMLNode * node in existingSShotsNodes)
    [node detach];

  query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/software_screenshots", language];
  NSArray * parentNodeArr = [self execXPath:query];
  // @TODO create this element if needed
  if (!parentNodeArr)
  {
    NSLog(@"ERROR: <software_screenshots> element doesn't exist");
    return NO;
  }

  // create new <software_screenshot> nodes with correct sizes and md5 hashes
  NSXMLElement * parent = [parentNodeArr objectAtIndex:0];
  NSFileManager * fileManager = [NSFileManager defaultManager];
  for (NSInteger i = 0; i < files.count; ++i)
  {
    // copy file to the actual xml location if needed, so Transporter tool will find it
    NSString * filePath = [files objectAtIndex:i];
    NSString * destinationFileName = [NSString stringWithFormat:@"%@_%@-%ld.%@", language, device, i + 1, filePath.pathExtension];
    NSString * destinationFullPath = [[self.pathToXml stringByDeletingLastPathComponent] stringByAppendingPathComponent:destinationFileName];
    if ([filePath isEqualToString:destinationFullPath])
      NSLog(@"INFO: File %@ is not copied as it's already present", filePath);
    else
    {
      [fileManager removeItemAtPath:destinationFullPath error:nil];
      NSError * err = nil;
      if (![fileManager copyItemAtPath:filePath toPath:destinationFullPath error:&err])
      {
        NSLog(@"ERROR %@ while copying %@ to %@", err.localizedDescription, filePath, destinationFullPath);
        continue;
      }
    }

    // calculate file's size
    NSNumber * fileSize = [NSNumber numberWithLongLong:[fileManager attributesOfItemAtPath:destinationFullPath error:nil].fileSize];

    // calculate file's md5 hash
    NSString * md5 = Md5ForFile(destinationFullPath);

    // create needed xml elements
    NSXMLElement * fileNameElement = [NSXMLElement elementWithName:@"file_name"];
    fileNameElement.stringValue = destinationFileName;
    NSXMLElement * fileSizeElement = [NSXMLElement elementWithName:@"size"];
    fileSizeElement.stringValue = fileSize.stringValue;
    NSXMLElement * fileChecksumElement = [NSXMLElement elementWithName:@"checksum"];
    fileChecksumElement.stringValue = md5;
    [fileChecksumElement addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"md5"]];

    NSXMLElement * sShotElement = [NSXMLElement elementWithName:@"software_screenshot"];
    sShotElement.attributes = @[[NSXMLNode attributeWithName:@"display_target" stringValue:device],
                                [NSXMLNode attributeWithName:@"position" stringValue:[NSString stringWithFormat:@"%ld", i + 1]]];

    [sShotElement addChild:fileNameElement];
    [sShotElement addChild:fileSizeElement];
    [sShotElement addChild:fileChecksumElement];
    [parent addChild:sShotElement];
  }
  return YES;
}

- (BOOL)setIPhone4Screenshots:(NSArray *)files forLanguage:(NSString *)language
{
  return [self setScreenshots:files forDevice:@"iOS-3.5-in" forLanguage:language];
}

- (BOOL)setIPhone5Screenshots:(NSArray *)files forLanguage:(NSString *)language
{
  return [self setScreenshots:files forDevice:@"iOS-4-in" forLanguage:language];
}

- (BOOL)setIPadScreenshots:(NSArray *)files forLanguage:(NSString *)language
{
  return [self setScreenshots:files forDevice:@"iOS-iPad" forLanguage:language];
}

- (NSString *)titleForLanguage:(NSString *)lang
{
  NSString * query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/title", lang];
  NSArray * res = [self execXPath:query];
  if (res.count == 1)
  {
    NSXMLElement * el = [res objectAtIndex:0];
    return el.stringValue;
  }

  NSLog(@"ERROR: Can't get title for language %@", lang);
  return @"";
}

- (BOOL)setTitle:(NSString *)title forLanguage:(NSString *)lang
{
  // Check constraints
  if (title.length < 2 || title.length > 255)
  {
    NSLog(@"ERROR: Title length is %lu but should be from 2 to 255 characters",
          (unsigned long)title.length);
    return NO;
  }

  NSString * query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/title", lang];
  NSArray * res = [self execXPath:query];
  if (res.count != 1)
  {
    NSLog(@"ERROR setting title, it doesn't exist in the xml");
    return NO;
  }
  NSXMLElement * el = [res objectAtIndex:0];
  assert(el.kind == NSXMLElementKind);
  el.stringValue = title;
  return YES;
}

- (NSString *)descriptionForLanguage:(NSString *)lang
{
  NSString * query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/description", lang];
  NSArray * res = [self execXPath:query];
  if (res.count == 1)
  {
    NSXMLElement * el = [res objectAtIndex:0];
    return el.stringValue;
  }

  NSLog(@"ERROR: Can't get description for language %@", lang);
  return @"";
}

- (BOOL)setDescription:(NSString *)description forLanguage:(NSString *)lang
{
  // Check constraints
  NSInteger const len = description.length;
  if (len < 10 || len > 4000)
  {
    NSLog(@"ERROR: Description length is %lu but should be from 10 to 4000 characters",
          (unsigned long)len);
    return NO;
  }

  NSString * query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/description", lang];
  NSArray * res = [self execXPath:query];
  if (res.count != 1)
  {
    NSLog(@"ERROR setting description, it doesn't exist in the xml");
    return NO;
  }
  NSXMLElement * el = [res objectAtIndex:0];
  assert(el.kind == NSXMLElementKind);
  // Replace all \n with \r to save formatting
  el.stringValue = [description stringByReplacingOccurrencesOfString:@"\n" withString:@"\r"];
  return YES;
}

- (NSString *)whatsNewForLanguage:(NSString *)lang
{
  NSString * query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/version_whats_new", lang];
  NSArray * res = [self execXPath:query];
  if (res.count == 1)
  {
    NSXMLElement * el = [res objectAtIndex:0];
    return el.stringValue;
  }

  NSLog(@"WARNING: Can't get What's New for language %@", lang);
  return @"";
}

- (BOOL)setWhatsNew:(NSString *)whatsNew forLanguage:(NSString *)lang
{
  // Check constraints
  NSInteger const len = whatsNew.length;
  if (len < 10 || len > 4000)
  {
    NSLog(@"ERROR: What's New length is %lu but should be from 10 to 4000 characters",
          (unsigned long)len);
    return NO;
  }

  NSString * query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/version_whats_new", lang];
  NSArray * res = [self execXPath:query];
  if (res.count != 1)
  {
    NSLog(@"ERROR setting What's New, it doesn't exist in the xml");
    return NO;
  }
  NSXMLElement * el = [res objectAtIndex:0];
  assert(el.kind == NSXMLElementKind);
  // Replace all \n with \r to save formatting
  el.stringValue = [whatsNew stringByReplacingOccurrencesOfString:@"\n" withString:@"\r"];
  return YES;
}

- (NSString *)keywordsForLanguage:(NSString *)lang
{
  NSString * query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/keywords/keyword", lang];
  NSArray * res = [self execXPath:query];
  if (!res)
  {
    NSLog(@"ERROR: Can't get keywords for language %@", lang);
    return @"";
  }
  NSMutableString * keywords = [[NSMutableString alloc] init];
  for (NSInteger i = 0; i < res.count; ++i)
  {
    NSXMLElement * el = [res objectAtIndex:i];
    [keywords appendString:el.stringValue];
    if (i != res.count - 1)
      [keywords appendString:@","];
  }
  return keywords;
}

- (BOOL)setKeywords:(NSString *)keywords forLanguage:(NSString *)lang
{
  // Check constraints
  if (keywords.length == 0 || keywords.length > 100)
  {
    NSLog(@"ERROR: keywords size is %lu characters, but should be less than 100",
          (unsigned long)keywords.length);
    return NO;
  }

  // First, remove all existing keywords
  NSString * query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/keywords", lang];
  NSArray * res = [self execXPath:query];
  if (!res)
  {
    NSLog(@"ERROR: keywords tag doesn't exist");
    return NO;
  }
  NSXMLElement * parent = [res objectAtIndex:0];
  for (NSXMLNode * node in parent.children)
    [node detach];

  // Create and add new keywords
  for (NSString * keyword in [keywords componentsSeparatedByString:@","])
  {
    NSXMLElement * el = [NSXMLElement elementWithName:@"keyword"];
    el.stringValue = keyword;
    [parent addChild:el];
//    NSLog(@"INFO: Added keyword %@", keyword);
  }

  return YES;
}

- (NSString *)supportUrlForLanguage:(NSString *)lang
{
  NSString * query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/support_url", lang];
  NSArray * res = [self execXPath:query];
  if (res.count == 1)
  {
    NSXMLElement * el = [res objectAtIndex:0];
    return el.stringValue;
  }

  NSLog(@"WARNING: Can't get Support URL for language %@", lang);
  return @"";
}

- (BOOL)setSupportUrl:(NSString *)url forLanguage:(NSString *)lang
{
  // Check constraints, empty url is not allowed!
  if (url.length < 2 || url.length > 255)
  {
    NSLog(@"ERROR: Support URL length is %lu but should be from 2 to 255 characters",
          (unsigned long)url.length);
    return NO;
  }

  NSString * query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/support_url", lang];
  NSArray * res = [self execXPath:query];
  if (res.count != 1)
  {
    // We need to create tag
    query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]", lang];
    res = [self execXPath:query];
    if (res.count != 1)
    {
      NSLog(@"ERROR: Locale %@ doesn't exist in XML for setting Support URL", lang);
      return NO;
    }
    NSXMLElement * parent = [res objectAtIndex:0];
    NSXMLElement * el = [NSXMLElement elementWithName:@"support_url"];
    el.stringValue = url;
    [parent addChild:el];
  }
  else
  {
    // Tag exists, just change it's text value
    NSXMLElement * el = [res objectAtIndex:0];
    assert(el.kind == NSXMLElementKind);
    el.stringValue = url;
  }
  return YES;
}

- (NSString *)marketingUrlForLanguage:(NSString *)lang
{
  NSString * query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/software_url", lang];
  NSArray * res = [self execXPath:query];
  if (res.count == 1)
  {
    NSXMLElement * el = [res objectAtIndex:0];
    return el.stringValue;
  }

  NSLog(@"WARNING: Can't get Marketing URL for language %@", lang);
  return @"";
}

- (BOOL)setMarketingUrl:(NSString *)url forLanguage:(NSString *)lang
{
  // Check constraints, empty url means delete it from the metadata
  if (url.length == 1 || url.length > 255)
  {
    NSLog(@"ERROR: Marketing URL length is %lu but should be from 2 to 255 characters",
          (unsigned long)url.length);
    return NO;
  }

  NSString * query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/software_url", lang];
  NSArray * res = [self execXPath:query];
  if (res.count != 1)
  {
    // We need to create tag
    query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]", lang];
    res = [self execXPath:query];
    if (res.count != 1)
    {
      NSLog(@"ERROR: Locale %@ doesn't exist in XML for setting Marketing URL", lang);
      return NO;
    }
    NSXMLElement * parent = [res objectAtIndex:0];
    NSXMLElement * el = [NSXMLElement elementWithName:@"software_url"];
    el.stringValue = url;
    [parent addChild:el];
  }
  else
  {
    // Tag exists, just change it's text value
    NSXMLElement * el = [res objectAtIndex:0];
    assert(el.kind == NSXMLElementKind);
    el.stringValue = url;
  }
  return YES;
}

- (NSString *)privacyPolicyUrlForLanguage:(NSString *)lang
{
  NSString * query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/privacy_url", lang];
  NSArray * res = [self execXPath:query];
  if (res.count == 1)
  {
    NSXMLElement * el = [res objectAtIndex:0];
    return el.stringValue;
  }

  NSLog(@"WARNING: Can't get Privacy Policy URL for language %@", lang);
  return @"";
}

- (BOOL)setPrivacyPolicyUrl:(NSString *)url forLanguage:(NSString *)lang
{
  // Check constraints, empty url means delete it from the metadata
  if (url.length == 1 || url.length > 255)
  {
    NSLog(@"ERROR: Privacy Policy URL length is %lu but should be from 2 to 255 characters",
          (unsigned long)url.length);
    return NO;
  }

  NSString * query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]/privacy_url", lang];
  NSArray * res = [self execXPath:query];
  if (res.count != 1)
  {
    // We need to create tag
    query = [NSString stringWithFormat:@"/package/software/software_metadata/versions/version/locales/locale[@name=\"%@\"]", lang];
    res = [self execXPath:query];
    if (res.count != 1)
    {
      NSLog(@"ERROR: Locale %@ doesn't exist in XML for setting Privacy Policy URL", lang);
      return NO;
    }
    NSXMLElement * parent = [res objectAtIndex:0];
    NSXMLElement * el = [NSXMLElement elementWithName:@"privacy_url"];
    el.stringValue = url;
    [parent addChild:el];
  }
  else
  {
    // Tag exists, just change it's text value
    NSXMLElement * el = [res objectAtIndex:0];
    assert(el.kind == NSXMLElementKind);
    el.stringValue = url;
  }
  return YES;
}

@end

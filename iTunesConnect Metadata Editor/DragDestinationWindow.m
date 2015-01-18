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

#import "DragDestinationWindow.h"
#import "ScreenShot.h"
#import "Globals.h"
#import "AppDelegate.h"

typedef enum
{
  ScreenTypeiPad,
  ScreenTypeiPhone4,
  ScreenTypeiPhone5,
  ScreenTypeUnsupported

} ScreenType;

// all supported resolutions
static NSInteger const g_resolutions[][3] =
{
  { 960, 640,   ScreenTypeiPhone4 },
  { 960, 600,   ScreenTypeiPhone4 },
  { 640, 960,   ScreenTypeiPhone4 },
  { 640, 920,   ScreenTypeiPhone4 },
  { 1136, 640,  ScreenTypeiPhone5 },
  { 1136, 600,  ScreenTypeiPhone5 },
  { 640, 1136,  ScreenTypeiPhone5 },
  { 640, 1096,  ScreenTypeiPhone5 },
  { 1024, 768,  ScreenTypeiPad },
  { 1024, 748,  ScreenTypeiPad },
  { 768, 1024,  ScreenTypeiPad },
  { 768, 1004,  ScreenTypeiPad },
  { 2048, 1536, ScreenTypeiPad },
  { 2048, 1496, ScreenTypeiPad },
  { 1536, 2048, ScreenTypeiPad },
  { 1536, 2008, ScreenTypeiPad }
};

@implementation ImageViewWithPath

@synthesize path = _path;

- (void)setPath:(NSString *)newPath
{
  if (!newPath)
  {
    _path = nil;
    self.image = nil;
  }
  else
  {
    _path = [newPath copy];
    self.image = [[NSImage alloc] initByReferencingFile:_path];
  }
}

// ******* Redirect DraggingDestination delegate to window *******

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
  return [(DragDestinationWindow *)_window draggingEntered:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
  return [(DragDestinationWindow *)_window draggingUpdated:sender];
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
  [(DragDestinationWindow *)_window draggingExited:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
  return [(DragDestinationWindow *)_window prepareForDragOperation:sender];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
  return [(DragDestinationWindow *)_window performDragOperation:sender];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
  [(DragDestinationWindow *)_window concludeDragOperation:sender];
}

@end


@implementation DragDestinationWindow

+ (BOOL)isPngOrJpeg:(NSURL *)path
{
  NSString * type;
  [path getResourceValue:&type forKey:NSURLTypeIdentifierKey error:NULL];
  if ([type isEqualToString:(NSString *)kUTTypePNG]
      || [type isEqualToString:(NSString *)kUTTypeJPEG]
      || [type isEqualToString:(NSString *)kUTTypeJPEG2000])
    return YES;

  return NO;
}

+ (ScreenType)screenType:(NSImage *)image
{
  CGSize const size = image.size;
  for (size_t i = 0; i < sizeof(g_resolutions)/sizeof(g_resolutions[0]); ++i)
    if (size.width == g_resolutions[i][0] && size.height == g_resolutions[i][1])
      return (ScreenType)g_resolutions[i][2];
  return ScreenTypeUnsupported;
}

+ (BOOL)isImageResolutionSupported:(NSURL *)imageUrl
{
  @autoreleasepool
  {
    NSImage * img = [[NSImage alloc] initByReferencingURL:imageUrl];
    switch ([DragDestinationWindow screenType:img])
    {
      case ScreenTypeiPad:
      case ScreenTypeiPhone4:
      case ScreenTypeiPhone5:
        return YES;
      default:
        return NO;
    }
  }
  return NO;
}

// @returns found NSURL images or nil if not found
+ (NSArray *)scanURLForImages:(NSURL *)pathToScan
{
  if ([DragDestinationWindow isPngOrJpeg:pathToScan])
  {
    if ([DragDestinationWindow isImageResolutionSupported:pathToScan])
      return @[pathToScan];
    return nil;
  }

  NSArray * cachedProps = @[NSURLTypeIdentifierKey];
  NSDirectoryEnumerator * enumerator = [[NSFileManager defaultManager] enumeratorAtURL:pathToScan
                                                            includingPropertiesForKeys:cachedProps
                                                                               options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                          errorHandler:nil];

  // An array to store the all the enumerated file names in
  NSMutableArray * foundImages = [NSMutableArray array];

  // Enumerate the dirEnumerator results, each value is stored in allURLs
  for (NSURL * theURL in enumerator)
  {
    if ([DragDestinationWindow isPngOrJpeg:theURL]
        && [DragDestinationWindow isImageResolutionSupported:theURL])
      [foundImages addObject:theURL];
  }
  return foundImages.count ? foundImages : nil;
}

+ (NSArray *)getImagesArrayFromPasteboard:(id <NSDraggingInfo>)sender
{
  NSPasteboard * pboard = [sender draggingPasteboard];
  if ([pboard.types containsObject:NSURLPboardType])
  {
    NSArray * urls = [pboard readObjectsForClasses:@[[NSURL class]] options:nil];
    NSMutableArray * res = [[NSMutableArray alloc] init];
    for (NSURL * url in urls)
    {
      NSArray * imagesInUrl = [DragDestinationWindow scanURLForImages:url];
      if (imagesInUrl)
        [res addObjectsFromArray:imagesInUrl];
    }
    return res.count ? res : nil;
  }
  return nil;
}

+ (NSString *)generateDestinationPath:(NSString *)srcPath forDevice:(ScreenType)device sshot:(NSInteger)number
{
  NSString * deviceStr;
  switch (device)
  {
    case ScreenTypeiPad: deviceStr = @"iOS-iPad"; break;
    case ScreenTypeiPhone4: deviceStr = @"iOS-3.5-in"; break;
    case ScreenTypeiPhone5: deviceStr = @"iOS-4-in"; break;
    default:
      NSLog(@"ERROR: unknown device type");
      assert(false);
  }
  NSString * language = ((AppDelegate *)[NSApp delegate]).currentLanguage;
  NSString * destinationFileName = [NSString stringWithFormat:@"%@_%@-%ld.%@", language, deviceStr, number, srcPath.pathExtension];
  NSString * destinationFullPath = [[((AppDelegate *)[NSApp delegate]).xmlProcessor.pathToXml stringByDeletingLastPathComponent] stringByAppendingPathComponent:destinationFileName];


  // @TODO also copy file here
  NSFileManager * fileManager = [NSFileManager defaultManager];
  [fileManager removeItemAtPath:destinationFullPath error:nil];
  NSError * err = nil;
  if (![fileManager copyItemAtPath:srcPath toPath:destinationFullPath error:&err])
  {
    NSLog(@"ERROR %@ while copying %@ to %@", err.localizedDescription, srcPath, destinationFullPath);
    return nil;
  }

  return destinationFullPath;
}

- (void)fillImageViews:(NSArray *)imageUrls
{
  NSInteger iPad = 1, iPhone4 = 1, iPhone5 = 1;
  for (NSURL * url in imageUrls)
  {
    NSImage * img = [[NSImage alloc] initByReferencingURL:url];
    ScreenType device = [DragDestinationWindow screenType:img];
    switch (device)
    {
      case ScreenTypeiPad:
      {
        NSString * path = [DragDestinationWindow generateDestinationPath:url.path forDevice:device sshot:iPad];
        switch (iPad)
        {
          case 1: self.iPad_1.path = path; break;
          case 2: self.iPad_2.path = path; break;
          case 3: self.iPad_3.path = path; break;
          case 4: self.iPad_4.path = path; break;
          case 5: self.iPad_5.path = path; break;
        }
        ++iPad;
        break;
      }

      case ScreenTypeiPhone4:
      {
        NSString * path = [DragDestinationWindow generateDestinationPath:url.path forDevice:device sshot:iPhone4];
        switch (iPhone4)
        {
          case 1: self.iPhone4_1.path = path; break;
          case 2: self.iPhone4_2.path = path; break;
          case 3: self.iPhone4_3.path = path; break;
          case 4: self.iPhone4_4.path = path; break;
          case 5: self.iPhone4_5.path = path; break;
        }
        ++iPhone4;
        break;
      }

      case ScreenTypeiPhone5:
      {
        NSString * path = [DragDestinationWindow generateDestinationPath:url.path forDevice:device sshot:iPhone5];
        switch (iPhone5)
        {
          case 1: self.iPhone5_1.path = path; break;
          case 2: self.iPhone5_2.path = path; break;
          case 3: self.iPhone5_3.path = path; break;
          case 4: self.iPhone5_4.path = path; break;
          case 5: self.iPhone5_5.path = path; break;
        }
        ++iPhone5;
        break;
      }

      default:
        NSLog(@"WARNING: Unsupported image - %@", url.path);
        break;
    }
  }
  NSLog(@"Total %lu images, %ld for iPad, %ld for iPhone4 and %ld for iPhone5", (unsigned long)imageUrls.count, (long)iPad - 1, (long)iPhone4 - 1, (long)iPhone5 - 1);

  // @TODO refactor
  // Copy dragged images to working folder
  XMLProcessor * xml = ((AppDelegate *)[NSApp delegate]).xmlProcessor;
  NSString * language = ((AppDelegate *)[NSApp delegate]).currentLanguage;
  if (iPhone4 > 1)
    [xml setIPhone4Screenshots:[self iPhone4ScreenshotsOrNil] forLanguage:language];
  if (iPhone5 > 1)
    [xml setIPhone5Screenshots:[self iPhone5ScreenshotsOrNil] forLanguage:language];
  if (iPad > 1)
    [xml setIPadScreenshots:[self iPadScreenshotsOrNil] forLanguage:language];
}

- (NSArray *)iPadScreenshotsOrNil
{
  NSMutableArray * res = [[NSMutableArray alloc] init];
  if (_iPad_1.path)
    [res addObject:_iPad_1.path];
  if (_iPad_2.path)
    [res addObject:_iPad_2.path];
  if (_iPad_3.path)
    [res addObject:_iPad_3.path];
  if (_iPad_4.path)
    [res addObject:_iPad_4.path];
  if (_iPad_5.path)
    [res addObject:_iPad_5.path];
  if (res.count)
    return res;
  return nil;
}

- (NSArray *)iPhone4ScreenshotsOrNil
{
  NSMutableArray * res = [[NSMutableArray alloc] init];
  if (_iPhone4_1.path)
    [res addObject:_iPhone4_1.path];
  if (_iPhone4_2.path)
    [res addObject:_iPhone4_2.path];
  if (_iPhone4_3.path)
    [res addObject:_iPhone4_3.path];
  if (_iPhone4_4.path)
    [res addObject:_iPhone4_4.path];
  if (_iPhone4_5.path)
    [res addObject:_iPhone4_5.path];
  if (res.count)
    return res;
  return nil;
}

- (NSArray *)iPhone5ScreenshotsOrNil
{
  NSMutableArray * res = [[NSMutableArray alloc] init];
  if (_iPhone5_1.path)
    [res addObject:_iPhone5_1.path];
  if (_iPhone5_2.path)
    [res addObject:_iPhone5_2.path];
  if (_iPhone5_3.path)
    [res addObject:_iPhone5_3.path];
  if (_iPhone5_4.path)
    [res addObject:_iPhone5_4.path];
  if (_iPhone5_5.path)
    [res addObject:_iPhone5_5.path];
  if (res.count)
    return res;
  return nil;
}

- (BOOL)equalHash:(NSString *)md5 forFile:(NSString *)filePath
{
  return [NSFileManager.defaultManager fileExistsAtPath:filePath]
    && [Md5ForFile(filePath) isEqualToString:md5];
}

- (void)setIPhone4Screenshots:(NSArray *)sshots
{
  NSString * workingDir = [((AppDelegate *)[NSApp delegate]).xmlProcessor.pathToXml stringByDeletingLastPathComponent];
  NSInteger counter = 0;
  for (NSInteger i = 0; i < sshots.count; ++i)
  {
    ScreenShot * s = [sshots objectAtIndex:i];
    NSString * fullPath = [workingDir stringByAppendingPathComponent:s.name];
    if ([self equalHash:s.md5 forFile:fullPath])
    {
      ImageViewWithPath * property = [self valueForKey:[NSString stringWithFormat:@"iPhone4_%ld", i + 1]];
      property.path = fullPath;
      ++counter;
    }
  }
  for (NSInteger i = counter; i < 5; ++i)
  {
    ImageViewWithPath * property = [self valueForKey:[NSString stringWithFormat:@"iPhone4_%ld", i + 1]];
    property.path = nil;
  }
}

- (void)setIPhone5Screenshots:(NSArray *)sshots
{
  NSString * workingDir = [((AppDelegate *)[NSApp delegate]).xmlProcessor.pathToXml stringByDeletingLastPathComponent];
  NSInteger counter = 0;
  for (NSInteger i = 0; i < sshots.count; ++i)
  {
    ScreenShot * s = [sshots objectAtIndex:i];
    NSString * fullPath = [workingDir stringByAppendingPathComponent:s.name];
    if ([self equalHash:s.md5 forFile:fullPath])
    {
      ImageViewWithPath * property = [self valueForKey:[NSString stringWithFormat:@"iPhone5_%ld", i + 1]];
      property.path = fullPath;
      ++counter;
    }
  }
  for (NSInteger i = counter; i < 5; ++i)
  {
    ImageViewWithPath * property = [self valueForKey:[NSString stringWithFormat:@"iPhone5_%ld", i + 1]];
    property.path = nil;
  }
}

- (void)setIPadScreenshots:(NSArray *)sshots
{
  NSString * workingDir = [((AppDelegate *)[NSApp delegate]).xmlProcessor.pathToXml stringByDeletingLastPathComponent];
  NSInteger counter = 0;
  for (NSInteger i = 0; i < sshots.count; ++i)
  {
    ScreenShot * s = [sshots objectAtIndex:i];
    NSString * fullPath = [workingDir stringByAppendingPathComponent:s.name];
    if ([self equalHash:s.md5 forFile:fullPath])
    {
      ImageViewWithPath * property = [self valueForKey:[NSString stringWithFormat:@"iPad_%ld", i + 1]];
      property.path = fullPath;
      ++counter;
    }
  }
  for (NSInteger i = counter; i < 5; ++i)
  {
    ImageViewWithPath * property = [self valueForKey:[NSString stringWithFormat:@"iPad_%ld", i + 1]];
    property.path = nil;
  }
}


// *************************** DraggingDestination delegate *******************************

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
  self.draggedUrls = [DragDestinationWindow getImagesArrayFromPasteboard:sender];
  if (self.draggedUrls)
    return NSDragOperationCopy;

  return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
  if (self.draggedUrls)
    return NSDragOperationCopy;
  return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
  self.draggedUrls = nil;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
  if (self.draggedUrls)
    return YES;
  return NO;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
  if (self.draggedUrls)
  {
    [self fillImageViews:self.draggedUrls];
    return YES;
  }

  return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
  self.draggedUrls = nil;
}

@end

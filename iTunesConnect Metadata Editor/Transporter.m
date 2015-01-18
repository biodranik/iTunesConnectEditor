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

#import "Transporter.h"


#define TRANSPORTER_XCODE_PATH @"/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/MacOS/itms/bin/iTMSTransporter"
#define TRANSPORTER_PATH @"/Applications/Application Loader.app/Contents/MacOS/itms/bin/iTMSTransporter"

@implementation Transporter

+ (NSString *)pathToBinary
{
  NSFileManager * mgr = [NSFileManager defaultManager];
  NSString * path = TRANSPORTER_XCODE_PATH;
  if (![mgr fileExistsAtPath:path])
  {
    path = TRANSPORTER_PATH;
    if (![mgr fileExistsAtPath:path])
    {
      NSLog(@"ERROR: iTunes Loader is not installed, please install it from iTunesConnect");
      return nil;
    }
  }
  return path;
}

- (BOOL)fetchMetaDataWithLogin:(NSString *)login
                            password:(NSString *)pass
                            vendorId:(NSString *)vendor
                     destinationPath:(NSString *)destination
{
  NSString * pathToBin = [Transporter pathToBinary];
  if (!pathToBin)
    return NO;

  NSTask * task = [[NSTask alloc] init];
  task.launchPath = pathToBin;

  task.arguments = @[@"-m", @"lookupMetadata", @"-u", login, @"-p", pass, @"-vendor_id", vendor, @"-destination", destination];

  NSPipe * outPipe = [NSPipe pipe];
  NSPipe * inPipe = [NSPipe pipe];
//  NSPipe * errPipe = [NSPipe pipe];
  task.standardOutput = outPipe;
  task.standardInput = inPipe;
//  task.standardError = errPipe;

  [task launch];

  // Synchronous blocking operation until task is finished
  NSData * data = [outPipe.fileHandleForReading readDataToEndOfFile];
//  NSData * errData = [errPipe.fileHandleForReading readDataToEndOfFile];
  [task waitUntilExit];

  // Log fetching result
  NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
  BOOL const wasError = (task.terminationStatus != 0);
//  if (wasError)
//    NSLog(@"ERROR while fetching metadata:\n%@", [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding]);

  return !wasError;
}

- (BOOL)verifyMetaDataWithLogin:(NSString *)login
                       password:(NSString *)pass
           existingMetadataPath:(NSString *)metadataPath
{
  NSString * pathToBin = [Transporter pathToBinary];
  if (!pathToBin)
    return NO;

  NSTask * task = [[NSTask alloc] init];
  task.launchPath = pathToBin;

  task.arguments = @[@"-m", @"verify", @"-u", login, @"-p", pass, @"-f", metadataPath];

  NSPipe * outPipe = [NSPipe pipe];
  NSPipe * inPipe = [NSPipe pipe];
//  NSPipe * errPipe = [NSPipe pipe];
  task.standardOutput = outPipe;
  task.standardInput = inPipe;
//  task.standardError = errPipe;

  [task launch];

  // Synchronous blocking operation until task is finished
  NSData * data = [outPipe.fileHandleForReading readDataToEndOfFile];
//  NSData * errData = [errPipe.fileHandleForReading readDataToEndOfFile];
  [task waitUntilExit];

  // Log fetching result
  NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
  BOOL const wasError = (task.terminationStatus != 0);
//  if (wasError)
//    NSLog(@"ERROR while verifying metadata:\n%@", [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding]);

  return !wasError;
}

- (BOOL)uploadMetaDataWithLogin:(NSString *)login
                       password:(NSString *)pass
           existingMetadataPath:(NSString *)metadataPath
{
  NSString * pathToBin = [Transporter pathToBinary];
  if (!pathToBin)
    return NO;

  NSTask * task = [[NSTask alloc] init];
  task.launchPath = pathToBin;

  task.arguments = @[@"-m", @"upload", @"-u", login, @"-p", pass, @"-f", metadataPath];

  NSPipe * outPipe = [NSPipe pipe];
  NSPipe * inPipe = [NSPipe pipe];
//  NSPipe * errPipe = [NSPipe pipe];
  task.standardOutput = outPipe;
  task.standardInput = inPipe;
//  task.standardError = errPipe;

  [task launch];

  // Synchronous blocking operation until task is finished
  NSData * data = [outPipe.fileHandleForReading readDataToEndOfFile];
//  NSData * errData = [errPipe.fileHandleForReading readDataToEndOfFile];
  [task waitUntilExit];

  // Log fetching result
  NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
  BOOL const wasError = (task.terminationStatus != 0);
//  if (wasError)
//    NSLog(@"ERROR while uploading metadata:\n%@", [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding]);

  return !wasError;
}


@end

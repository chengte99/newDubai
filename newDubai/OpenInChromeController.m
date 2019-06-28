#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

// Copyright 2012-2014, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <UIKit/UIKit.h>

#import "OpenInChromeController.h"

static NSString * const kGoogleChromeHTTPScheme = @"googlechrome://";
static NSString * const kGoogleChromeHTTPSScheme = @"googlechromes://";

@implementation OpenInChromeController

+ (OpenInChromeController *)sharedInstance {
  static OpenInChromeController *sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (BOOL)isChromeInstalled {
  NSURL *simpleURL = [NSURL URLWithString:kGoogleChromeHTTPScheme];
  return [[UIApplication sharedApplication] canOpenURL:simpleURL];
}

- (BOOL)openInChrome:(NSURL *)url {
  if ([self isChromeInstalled]) {
    NSString *scheme = [url.scheme lowercaseString];
    // Replace the URL Scheme with the Chrome equivalent.
    NSString *chromeScheme = nil;
    if ([scheme isEqualToString:@"http"]) {
      chromeScheme = kGoogleChromeHTTPScheme;
    } else if ([scheme isEqualToString:@"https"]) {
      chromeScheme = kGoogleChromeHTTPSScheme;
    }

    // Proceed only if a valid Google Chrome URI Scheme is available.
    if (chromeScheme) {
      NSString *absoluteString = [url absoluteString];
      NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
      NSString *urlNoScheme =
          [absoluteString substringFromIndex:rangeForScheme.location + 1];
      NSString *chromeURLString =
          [chromeScheme stringByAppendingString:urlNoScheme];
      NSURL *chromeURL = [NSURL URLWithString:chromeURLString];
      // Open the URL with Google Chrome.
      return [[UIApplication sharedApplication] openURL:chromeURL];
    }
  }
  return NO;
}

- (BOOL)openInChrome:(NSURL *)url
     withCallbackURL:(NSURL *)callbackURL
        createNewTab:(BOOL)createNewTab {
  // This deprecated API simply calls the supported -openInChrome: API.
  return [self openInChrome:url];
}
@end
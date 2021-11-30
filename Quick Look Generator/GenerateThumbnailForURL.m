#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>
#import "GNJEPUB.h"

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
  @autoreleasepool
  {
    if(![(__bridge NSString *)contentTypeUTI isEqualToString:GNJEPUBIDPFContentTypeUTI] &&
       ![(__bridge NSString *)contentTypeUTI isEqualToString:GNJEPUBAppleContentTypeUTI]) {
      return noErr;
    }

    GNJEPUB *epub = [[GNJEPUB alloc] initWithURL:(__bridge NSURL *)url];
    if(!epub) {
      NSLog(@"cannot create EPUB Object from '%@'.", (__bridge NSURL *)url);
      return noErr;
    }

    NSImage *coverImage = epub.coverImage;
    if(!coverImage) {
      return noErr;
    }

    QLThumbnailRequestSetImage(thumbnail, [coverImage CGImageForProposedRect:NULL context:nil hints:nil], NULL);
  }

  return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}

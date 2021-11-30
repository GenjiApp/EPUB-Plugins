//
//  GNJEPUB.h
//  EPUB Plugins
//
//  Created by Genji on 2015/03/11.
//
//

#import <Foundation/Foundation.h>
#import "GNJEPUBManifestItem.h"
#import "GNJEPUBMetadata.h"

extern NSString * const GNJEPUBIDPFContentTypeUTI;
extern NSString * const GNJEPUBAppleContentTypeUTI;

@interface GNJEPUB : NSObject

/** The manifest items, or an empty dictionary. This dictionary's key is identifier and the value is `GNJEPUBManifestItem` object. */
@property (nonatomic, strong, readonly) NSDictionary *manifestItems;

/** The spine items, or an empty array. An array of `GNJEPUBManifestItem` objects. */
@property (nonatomic, strong, readonly) NSArray *spineItems;

/** The `GNJEPUBMetadata` object stores the metadata of the EPUB, or `nil`. */
@property (nonatomic, strong, readonly) GNJEPUBMetadata *metadata;

/** The version string of the EPUB specification, or `nil`. */
@property (nonatomic, copy, readonly) NSString *EPUBVersion;

/** The cover image of the EPUB. `NSImage` object or `nil`. */
@property (nonatomic, strong, readonly) NSImage *coverImage;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFile:(NSString *)path NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithURL:(NSURL *)url;
- (NSData *)dataWithContentsOfFile:(NSString *)path;

@end

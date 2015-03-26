//
//  GNJEPUBManifestItem.h
//  EPUB Plugins
//
//  Created by Genji on 2015/04/03.
//
//

#import <Foundation/Foundation.h>

@interface GNJEPUBManifestItem : NSObject

/** An item's relative path from the root of the EPUB container. パーセントエンコーディングは解除済み。 */
@property (nonatomic, copy, readonly) NSString *path;

/** An item's MIME media type. */
@property (nonatomic, copy, readonly) NSString *mediaType;

/** An identifier of a fallback item. */
@property (nonatomic, copy, readonly) NSString *fallback;

/** The properties of an item. An array of `NSString` object. */
@property (nonatomic, strong, readonly) NSArray *properties;

/** An identifier of a media overlay item. */
@property (nonatomic, copy, readonly) NSString *mediaOverlay;

- (instancetype)initWithItemNode:(NSXMLNode *)itemNode basePath:(NSString *)basePath NS_DESIGNATED_INITIALIZER;

@end


@interface NSDictionary (GNJEPUBManifestItemAddition)

- (GNJEPUBManifestItem *)gnj_itemWithPath:(NSString *)path;
- (GNJEPUBManifestItem *)gnj_itemWithProperty:(NSString *)property;

@end

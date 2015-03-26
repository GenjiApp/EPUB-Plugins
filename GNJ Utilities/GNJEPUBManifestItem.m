//
//  GNJEPUBManifestItem.m
//  EPUB Plugins
//
//  Created by Genji on 2015/04/03.
//
//

#import "GNJEPUBManifestItem.h"
#import "GNJUtilities.h"

@interface GNJEPUBManifestItem ()

@property (nonatomic, copy, readwrite) NSString *path;
@property (nonatomic, copy, readwrite) NSString *mediaType;
@property (nonatomic, copy, readwrite) NSString *fallback;
@property (nonatomic, strong, readwrite) NSArray *properties;
@property (nonatomic, copy, readwrite) NSString *mediaOverlay;

@end

@implementation GNJEPUBManifestItem

- (instancetype)initWithItemNode:(NSXMLNode *)itemNode basePath:(NSString *)basePath
{
  if(!itemNode || ![itemNode.localName isEqualToString:@"item"]) {
    return nil;
  }

  self = [super init];
  if(self) {
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    NSXMLNode *hrefAttributeNode = [itemNode gnj_attributeNodeForLocalName:@"href"];
    NSString *path = [hrefAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
    if(!path.absolutePath) {
      path = [basePath stringByAppendingPathComponent:path];
    }
    path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if(!path.length) {
      return nil;
    }
    self.path = path;

    NSXMLNode *mediaTypeAttributeNode = [itemNode gnj_attributeNodeForLocalName:@"media-type"];
    self.mediaType = [mediaTypeAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];

    NSXMLNode *fallbackAttributeNode = [itemNode gnj_attributeNodeForLocalName:@"fallback"];
    self.fallback = [fallbackAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];

    NSXMLNode *propertiesAttributeNode = [itemNode gnj_attributeNodeForLocalName:@"properties"];
    NSString *propertiesAttributeValue = [propertiesAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
    self.properties = [propertiesAttributeValue componentsSeparatedByString:@" "];

    NSXMLNode *mediaOverlayAttributeNode = [itemNode gnj_attributeNodeForLocalName:@"media-overlay"];
    self.mediaOverlay = [mediaOverlayAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
  }

  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"path: %@, media-type: %@, properties: %@, fallback: %@, media-overlay: %@", self.path, self.mediaType, [self.properties componentsJoinedByString:@", "], self.fallback, self.mediaOverlay];
}

@end


@implementation NSDictionary (GNJEPUBManifestItemAddition)

- (GNJEPUBManifestItem *)gnj_itemWithPath:(NSString *)path
{
  for(NSString *key in self) {
    GNJEPUBManifestItem *item = self[key];
    if([item.path isEqualToString:path]) {
      return item;
    }
  }

  return nil;
}

- (GNJEPUBManifestItem *)gnj_itemWithProperty:(NSString *)property
{
  for(NSString *key in self) {
    GNJEPUBManifestItem *item = self[key];
    if([item.properties containsObject:property]) {
      return item;
    }
  }

  return nil;
}

@end

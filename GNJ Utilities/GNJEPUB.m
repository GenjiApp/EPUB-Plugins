//
//  GNJEPUB.m
//  EPUB Plugins
//
//  Created by Genji on 2015/03/11.
//
//

#import <Cocoa/Cocoa.h>
#import "GNJEPUB.h"
#import "GNJUnZip.h"
#import "GNJUtilities.h"

NSString * const GNJEPUBContentTypeUTI = @"org.idpf.epub-container";

@interface GNJEPUB ()

@property (nonatomic, strong, readwrite) GNJUnZip *unzip;
@property (nonatomic, copy, readwrite) NSString *OPFFilePath;
@property (nonatomic, strong, readwrite) NSXMLDocument *OPFFileXMLDocument;

@end

@implementation GNJEPUB
{
  NSDictionary *_internalManifestItems;
  NSArray *_internalSpineItems;
  GNJEPUBMetadata *_internalMetadata;
  NSString *_internalEPUBVersion;
  NSImage *_internalCoverImage;
}

- (instancetype)initWithFile:(NSString *)path
{
  self = [super init];
  if(self) {
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    GNJUnZip *unzip = [[GNJUnZip alloc] initWithZipFile:path];

    NSData *containerXMLData = [unzip dataWithContentsOfFile:@"META-INF/container.xml"];
    if(!containerXMLData) {
      NSLog(@"cannot read 'META-INF/container.xml' file from '%@'.", path);
      return nil;
    }

    NSXMLDocument *containerXMLDocument = [[NSXMLDocument alloc] initWithData:containerXMLData options:NSXMLDocumentTidyXML error:NULL];
    if(!containerXMLDocument) {
      NSLog(@"cannot create NSXMLDocument 'META-INF/container.xml' file.");
      return nil;
    }

    NSArray *fullPathAttributeNodes = [containerXMLDocument nodesForXPath:@"/*[local-name()='container']/*[local-name()='rootfiles']/*[local-name()='rootfile']/@*[local-name()='full-path']" error:NULL];
    if(!fullPathAttributeNodes.count) {
      NSLog(@"cannot find '/container/rootfiles/rootfile/@full-path' attribute.");
      return nil;
    }
    NSXMLNode *fullPathAttributeNode = fullPathAttributeNodes[0];
    NSString *OPFFilePath = [fullPathAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
    OPFFilePath = [OPFFilePath stringByRemovingPercentEncoding];

    NSData *OPFFileData = [unzip dataWithContentsOfFile:OPFFilePath];
    if(!OPFFileData) {
      NSLog(@"cannot read '%@' file from zip.", OPFFilePath);
      return nil;
    }
    NSXMLDocument *OPFFileXMLDocument = [[NSXMLDocument alloc] initWithData:OPFFileData options:NSXMLDocumentTidyXML error:NULL];
    if(!OPFFileXMLDocument) {
      NSLog(@"cannot create NSXMLDocument '%@' file.", OPFFilePath);
      return nil;
    }

    self.unzip = unzip;
    self.OPFFilePath = OPFFilePath;
    self.OPFFileXMLDocument = OPFFileXMLDocument;
  }

  return self;
}

- (instancetype)initWithURL:(NSURL *)url
{
  return [self initWithFile:url.path];
}


#pragma mark -
#pragma mark Public Method
- (NSData *)dataWithContentsOfFile:(NSString *)path
{
  return [self.unzip dataWithContentsOfFile:path];
}


#pragma mark -
#pragma mark Accessor Methods
- (NSDictionary *)manifestItems
{
  if(_internalManifestItems) {
    return _internalManifestItems;
  }

  NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  NSString *basePath = [self.OPFFilePath stringByDeletingLastPathComponent];
  NSMutableDictionary *manifestItems = [NSMutableDictionary dictionary];
  NSArray *manifestItemNodes = [self.OPFFileXMLDocument nodesForXPath:@"/*[local-name()='package']/*[local-name()='manifest']/*[local-name()='item']" error:NULL];
  for(NSXMLNode *manifestItemNode in manifestItemNodes) {
    NSXMLNode *idAttributeNode = [manifestItemNode gnj_attributeNodeForLocalName:@"id"];
    NSString *idAttributeValue = [idAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
    if(idAttributeValue.length) {
      GNJEPUBManifestItem *manifestItem = [[GNJEPUBManifestItem alloc] initWithItemNode:manifestItemNode basePath:basePath];
      manifestItems[idAttributeValue] = manifestItem;
    }
  }

  return _internalManifestItems = manifestItems;
}

- (NSArray *)spineItems
{
  if(_internalSpineItems) {
    return _internalSpineItems;
  }

  NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  NSMutableArray *spineItems = [NSMutableArray array];
  NSArray *idRefAttributeNodes = [self.OPFFileXMLDocument nodesForXPath:@"/*[local-name()='package']/*[local-name()='spine']/*[local-name()='itemref']/@*[local-name()='idref']" error:NULL];
  for(NSXMLNode *idRefAttributeNode in idRefAttributeNodes) {
    NSString *idRefAttributeValue = [idRefAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
    GNJEPUBManifestItem *item = self.manifestItems[idRefAttributeValue];
    if(item) {
      [spineItems addObject:item];
    }
  }

  return _internalSpineItems = spineItems;
}

- (GNJEPUBMetadata *)metadata
{
  if(_internalMetadata) {
    return _internalMetadata;
  }

  GNJEPUBMetadata *metadata = [[GNJEPUBMetadata alloc] initWithOPFXMLDocument:self.OPFFileXMLDocument];
  return _internalMetadata = metadata;
}

- (NSString *)EPUBVersion
{
  if(_internalEPUBVersion) {
    return _internalEPUBVersion;
  }

  NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  NSXMLNode *versionAttributeNode = [[self.OPFFileXMLDocument nodesForXPath:@"/*[local-name()='package']/@*[local-name()='version']" error:NULL] firstObject];
  return _internalEPUBVersion = [versionAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
}

- (NSImage *)coverImage
{
  if(_internalCoverImage) {
    return _internalCoverImage;
  }

  NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  NSXMLNode *hrefAttributeNode = [[self.OPFFileXMLDocument nodesForXPath:@"/*[local-name()='package']/*[local-name()='manifest']/*[local-name()='item' and contains(concat(' ', normalize-space(@properties), ' '), ' cover-image ')]/@*[local-name()='href']" error:NULL] firstObject];
  if(!hrefAttributeNode) {
    NSXMLNode *contentAttributeNode = [[self.OPFFileXMLDocument nodesForXPath:@"/*[local-name()='package']/*[local-name()='metadata']/*[local-name()='meta' and @name='cover']/@*[local-name()='content']" error:NULL] firstObject];
    NSString *coverImageIdentifier = [contentAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
    if(!coverImageIdentifier.length) {
      return nil;
    }
    NSString *xpath = [NSString stringWithFormat:@"/*[local-name()='package']/*[local-name()='manifest']/*[local-name()='item' and @id='%@']/@*[local-name()='href']", coverImageIdentifier];
    hrefAttributeNode = [[self.OPFFileXMLDocument nodesForXPath:xpath error:NULL] firstObject];
    if(!hrefAttributeNode) {
      return nil;
    }
  }

  NSString *coverImagePath = [hrefAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
  coverImagePath = [coverImagePath stringByRemovingPercentEncoding];
  if(!coverImagePath.absolutePath) {
    NSString *basePath = [self.OPFFilePath stringByDeletingLastPathComponent];
    coverImagePath = [basePath stringByAppendingPathComponent:coverImagePath];
  }

  NSData *coverImageData = [self dataWithContentsOfFile:coverImagePath];
  if(!coverImageData) {
    NSLog(@"cannot read cover-image data from the EPUB file '%@'.", coverImagePath);
    return nil;
  }

  return _internalCoverImage = [[NSImage alloc] initWithData:coverImageData];
}

@end

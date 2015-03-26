//
//  GNJEPUBMetadata.m
//  EPUB Plugins
//
//  Created by Genji on 2015/03/23.
//
//

#import "GNJEPUBMetadata.h"
#import "GNJUtilities.h"

@interface GNJEPUBMetadata ()

@property (nonatomic, strong) NSXMLNode *metadataNode;

@end

@implementation GNJEPUBMetadata

- (instancetype)initWithOPFXMLDocument:(NSXMLDocument *)OPFXMLDocument
{
  self = [super init];
  if(self) {
    NSXMLNode *metadataNode = [[OPFXMLDocument nodesForXPath:@"/*[local-name()='package']/*[local-name()='metadata']" error:NULL] firstObject];
    if(!metadataNode) {
      return nil;
    }

    self.metadataNode = metadataNode;
  }

  return self;
}


#pragma mark -
#pragma mark Private Methods
- (NSString *)stringValueOfMetadataName:(NSString *)metadataName
{
  NSXMLNode *node = [self.metadataNode gnj_childNodeForLocalName:metadataName];
  if(!node) {
    return nil;
  }

  static NSCharacterSet *whitespaceAndNewlineCharacterSet = nil;
  if(!whitespaceAndNewlineCharacterSet) {
    whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  }

  return [node.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
}

- (NSArray *)stringValuesOfMetadataName:(NSString *)metadataName
{
  NSArray *nodes = [self.metadataNode gnj_childNodesForLocalName:metadataName];
  if(!nodes.count) {
    return nil;
  }

  static NSCharacterSet *whitespaceAndNewlineCharacterSet = nil;
  if(!whitespaceAndNewlineCharacterSet) {
    whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  }

  NSMutableArray *stringValues = [NSMutableArray array];
  for(NSXMLNode *node in nodes) {
    NSString *stringValue = [node.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
    if(stringValue.length) {
      [stringValues addObject:stringValue];
    }
  }

  return stringValues.count ? stringValues : nil;
}


#pragma mark -
#pragma mark Accessor Methods
- (NSArray *)titles
{
  return [self stringValuesOfMetadataName:@"title"];
}

- (NSArray *)creators
{
  return [self stringValuesOfMetadataName:@"creator"];
}

- (NSArray *)subjects
{
  return [self stringValuesOfMetadataName:@"subject"];
}

- (NSString *)descriptionText
{
  return [self stringValueOfMetadataName:@"description"];
}

- (NSArray *)publishers
{
  return [self stringValuesOfMetadataName:@"publisher"];
}

- (NSArray *)contributors
{
  return [self stringValuesOfMetadataName:@"contributor"];
}

- (NSArray *)identifiers
{
  return [self stringValuesOfMetadataName:@"identifier"];
}

- (NSArray *)languages
{
  return [self stringValuesOfMetadataName:@"language"];
}

- (NSString *)coverage
{
  return [self stringValueOfMetadataName:@"coverage"];
}

- (NSString *)copyright
{
  return [self stringValueOfMetadataName:@"rights"];
}

- (NSDate *)publicationDate
{
  NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  NSArray *dateNodes = [self.metadataNode gnj_childNodesForLocalName:@"date"];
  for(NSXMLNode *dateNode in dateNodes) {
    NSXMLNode *eventAttributeNode = [dateNode gnj_attributeNodeForLocalName:@"event"];
    NSString *eventAttributeValue = [eventAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
    if(!eventAttributeNode || [eventAttributeValue isEqualToString:@"publication"]) {
      NSString *dateString = [dateNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
      return [dateString gnj_dateFromW3CDateAndTimeFormat];
    }
  }

  return nil;
}

- (NSDate *)lastModifiedDate
{
  NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  NSArray *metaNodes = [self.metadataNode nodesForXPath:@"*[local-name()='meta']" error:NULL];
  for(NSXMLNode *metaNode in metaNodes) {
    NSXMLNode *propertyAttributeNode = [metaNode gnj_attributeNodeForLocalName:@"property"];
    NSString *propertyAttributeValue = [propertyAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
    if([propertyAttributeValue isEqualToString:@"dcterms:modified"]) {
      NSString *dateString = [metaNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
      return [dateString gnj_dateFromW3CDateAndTimeFormat];
    }
  }

  NSArray *dateNodes = [self.metadataNode gnj_childNodesForLocalName:@"date"];
  for(NSXMLNode *dateNode in dateNodes) {
    NSXMLNode *eventAttributeNode = [dateNode gnj_attributeNodeForLocalName:@"event"];
    NSString *eventAttributeValue = [eventAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
    if([eventAttributeValue isEqualToString:@"modification"]) {
      NSString *dateString = [dateNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
      return [dateString gnj_dateFromW3CDateAndTimeFormat];
    }
  }

  return nil;
}

@end

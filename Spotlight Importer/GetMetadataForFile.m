//
//  GetMetadataForFile.m
//  Spotlight Importer
//
//  Created by Genji on 2015/03/03.
//
//

#include <CoreFoundation/CoreFoundation.h>
#import <Cocoa/Cocoa.h>
#import "GNJEPUB.h"

static NSString * const kEPUBVersionAttributeName = @"com_genjiapp_Murasaki_mdimporter_EPUB_EPUBVersion";

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile);

//==============================================================================
//
//	Get metadata attributes from document files
//
//	The purpose of this function is to extract useful information from the
//	file formats for your document, and set the values into the attribute
//  dictionary for Spotlight to include.
//
//==============================================================================

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
  @autoreleasepool
  {
    if(![(__bridge NSString *)contentTypeUTI isEqualToString:GNJEPUBContentTypeUTI]) {
      return false;
    }

    GNJEPUB *epub = [[GNJEPUB alloc] initWithFile:(__bridge NSString *)pathToFile];
    if(!epub) {
      NSLog(@"cannot create EPUB Object from '%@'.", (__bridge NSString *)pathToFile);
      return false;
    }
    GNJEPUBMetadata *metadata = epub.metadata;

    NSMutableDictionary *attributesDict = (__bridge NSMutableDictionary *)attributes;
    NSArray *titles = metadata.titles;
    if(titles.count) {
      attributesDict[(NSString *)kMDItemTitle] = [titles componentsJoinedByString:@", "];
    }

    NSArray *creators = metadata.creators;
    if(creators.count) {
      attributesDict[(NSString *)kMDItemAuthors] = creators;
    }

    NSArray *subjects = metadata.subjects;
    if(subjects.count) {
      attributesDict[(NSString *)kMDItemKeywords] = subjects;
    }

    NSString *descriptionText = metadata.descriptionText;
    if(descriptionText.length) {
      attributesDict[(NSString *)kMDItemDescription] = descriptionText;
      attributesDict[(NSString *)kMDItemHeadline] = descriptionText;
    }

    NSArray *publishers = metadata.publishers;
    if(publishers.count) {
      attributesDict[(NSString *)kMDItemPublishers] = publishers;
      attributesDict[(NSString *)kMDItemOrganizations] = publishers;
    }

    NSArray *contributors = metadata.contributors;
    if(contributors.count) {
      attributesDict[(NSString *)kMDItemContributors] = contributors;
    }

    NSArray *identifiers = metadata.identifiers;
    if(identifiers.count) {
      attributesDict[(NSString *)kMDItemIdentifier] = [identifiers componentsJoinedByString:@", "];
    }

    NSArray *languages = metadata.languages;
    if(languages.count) {
      attributesDict[(NSString *)kMDItemLanguages] = languages;
    }

    NSString *coverage = metadata.coverage;
    if(coverage.length) {
      attributesDict[(NSString *)kMDItemCoverage] = coverage;
    }

    NSString *copyright = metadata.copyright;
    if(copyright.length) {
      attributesDict[(NSString *)kMDItemCopyright] = copyright;
      attributesDict[(NSString *)kMDItemRights] = copyright;
    }

    NSDate *publicationDate = metadata.publicationDate;
    NSDate *lastModifiedDate = metadata.lastModifiedDate;
    if(!publicationDate && lastModifiedDate) {
      publicationDate = lastModifiedDate;
    }
    else if(publicationDate && !lastModifiedDate) {
      lastModifiedDate = publicationDate;
    }
    if(publicationDate) {
      attributesDict[(NSString *)kMDItemContentCreationDate] = publicationDate;
    }
    if(lastModifiedDate) {
      attributesDict[(NSString *)kMDItemContentModificationDate] = lastModifiedDate;
    }

    NSMutableString *textContents = [NSMutableString string];
    for(GNJEPUBManifestItem *item in epub.spineItems) {
      NSData *contentDocumentData = [epub dataWithContentsOfFile:item.path];
      if(!contentDocumentData) {
        NSLog(@"cannot read data from the epub specified by the path '%@'.", item.path);
        continue;
      }
      NSXMLDocument *contentDocumentXMLDocument = [[NSXMLDocument alloc] initWithData:contentDocumentData options:NSXMLDocumentTidyXML error:NULL];
      if(!contentDocumentXMLDocument) {
        NSLog(@"cannot create NSXMLDocument from data specified by the path '%@'.", item.path);
        continue;
      }
      NSArray *textNodes = [contentDocumentXMLDocument nodesForXPath:@"//*[local-name()='body']//text()" error:NULL];
      for(NSXMLNode *textNode in textNodes) {
        [textContents appendFormat:@"%@ ", textNode.stringValue];
      }
    }

    if(epub.spineItems.count) {
      attributesDict[(NSString *)kMDItemNumberOfPages] = @(epub.spineItems.count);
    }

    if(textContents.length) {
      attributesDict[(NSString *)kMDItemTextContent] = textContents;
    }

    if(epub.EPUBVersion.length) {
      attributesDict[kEPUBVersionAttributeName] = epub.EPUBVersion;
    }
  }

  return true;
}

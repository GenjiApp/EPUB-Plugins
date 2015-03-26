//
//  GNJUtilities.m
//  EPUB Plugins
//
//  Created by Genji on 2015/03/23.
//
//

#import "GNJUtilities.h"

@implementation NSString (GNJUtilities)

- (NSString *)gnj_stringByNormalizingPathForZip
{
  NSString *normalizingPath = self;
  if(!normalizingPath.absolutePath) {
    normalizingPath = [@"/" stringByAppendingPathComponent:normalizingPath];
  }
  normalizingPath = [normalizingPath stringByStandardizingPath];
  return [normalizingPath substringFromIndex:1];
}

- (NSDate *)gnj_dateFromW3CDateAndTimeFormat
{
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
  dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
  dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
  NSDate *date = [dateFormatter dateFromString:self];
  if(date) {
    return date;
  }

  dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
  date = [dateFormatter dateFromString:self];
  if(date) {
    return date;
  }

  dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mmZ";
  date = [dateFormatter dateFromString:self];
  if(date) {
    return date;
  }

  dateFormatter.dateFormat = @"yyyy-MM-dd";
  date = [dateFormatter dateFromString:self];
  if(date) {
    return date;
  }

  dateFormatter.dateFormat = @"yyyy-MM";
  date = [dateFormatter dateFromString:self];
  if(date) {
    return date;
  }

  dateFormatter.dateFormat = @"yyyy";
  date = [dateFormatter dateFromString:self];
  if(date) {
    return date;
  }

  return nil;
}

- (NSString *)gnj_MIMETypeString
{
  CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)self, NULL);
  CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
  CFRelease(UTI);

  return CFBridgingRelease(MIMEType);
}

@end


@implementation NSXMLNode (GNJUtilities)

- (NSXMLNode *)gnj_attributeNodeForLocalName:(NSString *)localName
{
  if(!localName.length){
    return nil;
  }

  NSString *xpath = [NSString stringWithFormat:@"@*[local-name()='%@']", localName];
  NSArray *nodes = [self nodesForXPath:xpath error:NULL];

  return [nodes firstObject];
}

- (NSArray *)gnj_childNodesForLocalName:(NSString *)localName
{
  NSString *xpath = [NSString stringWithFormat:@"*[local-name()='%@']", localName];
  return [self nodesForXPath:xpath error:NULL];
}

- (NSXMLNode *)gnj_childNodeForLocalName:(NSString *)localName
{
  return [[self gnj_childNodesForLocalName:localName] firstObject];
}

@end

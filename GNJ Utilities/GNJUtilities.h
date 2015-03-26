//
//  GNJUtilities.h
//  EPUB Plugins
//
//  Created by Genji on 2015/03/23.
//
//

#import <Foundation/Foundation.h>

@interface NSString (GNJUtilities)

/** 
 * Returns a new string made by nomalizing path components for zip.
 * 
 * 絶対パスならば、`stringByStandardizingPath` でパス中の `.` や `..` を解決し、
 * 先頭の `/` を除いた文字列を返す。相対パスならば、先頭に `/` を加えて絶対パス化し、
 * あとは絶対パスの時と同じ処理をする。
 */
- (NSString *)gnj_stringByNormalizingPathForZip;

/** Returns a new date object made from W3C Date and Time format string, or `nil`. */
- (NSDate *)gnj_dateFromW3CDateAndTimeFormat;

/** Returns a MIME type string made from the receiver (file extension string), or `nil`. */
- (NSString *)gnj_MIMETypeString;

@end


@interface NSXMLNode (GNJUtilities)

/**
 * Returns the attribute node of the receiver that is identified by a local name, or `nil`.
 *
 * This method invokes `[self nodesForXPath:@"@*[local-name()='localName']" error:NULL]`,
 * and returns the first attribute node.
 *
 * @param localName A string specifying the local name of an attribute.
 * @return An XML node object representing a matching attribute or `nil` if no such node was found.
 */
- (NSXMLNode *)gnj_attributeNodeForLocalName:(NSString *)localName;

/**
 * Returns the child element nodes of the receiver that is identified by a given local name, or empty array.
 *
 * This method invokes `[self nodesForXPath:@"*[local-name()='localName']" error:NULL]`,
 * and returns the result array object.
 *
 * @param localName A string specifying the local name of a child element.
 * @return An array of the child element nodes that is identified by a given local name.
 */
- (NSArray *)gnj_childNodesForLocalName:(NSString *)localName;

/**
 * Returns the child element node of the receiver that is identified by a given local name, or `nil`.
 *
 * This method invokes `[self GNJ_childNodesForLocalName:localName]`,
 * and returns the first object of returned array.
 *
 * @param localName A string specifying the local name of a child element.
 * @return An array of the child element nodes that is identified by a given local name.
 */
- (NSXMLNode *)gnj_childNodeForLocalName:(NSString *)localName;

@end

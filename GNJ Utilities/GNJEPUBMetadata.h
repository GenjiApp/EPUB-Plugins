//
//  GNJEPUBMetadata.h
//  EPUB Plugins
//
//  Created by Genji on 2015/03/23.
//
//

#import <Foundation/Foundation.h>

@interface GNJEPUBMetadata : NSObject

/*
 * 以下のプロパティは呼び出しの際、毎回XML解析を行う。
 */
@property (nonatomic, readonly) NSArray *titles;
@property (nonatomic, readonly) NSArray *creators;
@property (nonatomic, readonly) NSArray *subjects;
@property (nonatomic, readonly) NSString *descriptionText;
@property (nonatomic, readonly) NSArray *publishers;
@property (nonatomic, readonly) NSArray *contributors;
@property (nonatomic, readonly) NSArray *identifiers;
@property (nonatomic, readonly) NSArray *languages;
@property (nonatomic, readonly) NSString *coverage;
@property (nonatomic, readonly) NSString *copyright;
@property (nonatomic, readonly) NSDate *publicationDate;
@property (nonatomic, readonly) NSDate *lastModifiedDate;

- (instancetype)initWithOPFXMLDocument:(NSXMLDocument *)OPFXMLDocument NS_DESIGNATED_INITIALIZER;

@end

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>
#import "GNJEPUB.h"
#import "GNJUtilities.h"

/** `GeneratePreviewForURL` 関数が呼び出されるコンテキストの種類 (undocumented)。 */
typedef NS_ENUM(NSInteger, GNJQLPreviewMode) {
  kGNJQLPreviewModeNone = 0,
  kGNJQLPreviewModeGetInfo = 1,
  kGNJQLPreviewModeCoverFlow = 2,
  kGNJQLPreviewModeNormalPreview = 5,
  kGNJQLPreviewModeSpotlightPreview = 8,
};

/** The key name which is used by `options` dictionary of `GeneratePreviewForURL` function (undocumented). */
static NSString * const kGNJQLPreviewModeKey = @"QLPreviewMode";

/** 順次読み込んでいくコンテントドキュメントのバイト数の積算が、これを超えた時点で以降のコンテントドキュメントは読み込まない（ざっくり）。 */
static const NSUInteger kMaxLenghOfContents = 1024 * 1024;

/**
 * Returns a <div> element contains child element nodes of content document's <body> element.
 *
 * スタイル関係の記述は <style scoped> に纏めて <div> の中に埋め込む。
 *
 * @param preview `QLPreviewRequest` object which is used to cancel previewing.
 * @param XHTMLContentDocumentData The contents data of the content document.
 * @param epub an EPUB object.
 * @param basePath The base path of the content document.
 * @param attachments The dictionary stores the additional resources data.
 * @param additionalResourceDataLength Upon returns, contains the number of bytes of the additional resources (i.e. images) contained in the content document.
 * @return a <div> element contains child element nodes of content document's <body> element.
 */
static NSXMLElement *generateDivElementOfXHTMLContentDocument(QLPreviewRequestRef preview, NSData *XHTMLContentDocumentData, GNJEPUB *epub, NSString *basePath, NSMutableDictionary *attachments, NSUInteger *additionalResourceDataLength);

/**
 * Returns a <div> element contains an <img> element.
 *
 * @param imagePath an image path.
 * @return a <div> element contains an <img> element.
 */
static NSXMLElement *generateDivElementOfImageContentDocument(NSString *imagePath);

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
 Generate a preview for file

 This function's job is to create preview for designated file
 ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
  @autoreleasepool
  {
    if(![(__bridge NSString *)contentTypeUTI isEqualToString:GNJEPUBContentTypeUTI]) {
      return noErr;
    }

    // GeneratePreviewForURL() の引数 options に関して、どんな状況で中身に何が入ってくるのか
    // ドキュメントには明記されていない。
    // `QLPreviewMode` キィには Quick Look を起動した状況に応じて値が入ってくるようである。
    // Finder の「情報を見る」や Cover Flow 表示のときは、ここでプレヴューを生成しなくても
    // アイコン用のサムネイル生成処理が走るようだ。
    GNJQLPreviewMode previewMode = [[(__bridge NSDictionary *)options objectForKey:kGNJQLPreviewModeKey] integerValue];
    if(previewMode == kGNJQLPreviewModeGetInfo ||
       previewMode == kGNJQLPreviewModeCoverFlow) {
      return noErr;
    }

    GNJEPUB *epub = [[GNJEPUB alloc] initWithURL:(__bridge NSURL *)url];
    if(!epub) {
      NSLog(@"cannot create EPUB Object from '%@'.", (__bridge NSURL *)url);
      return noErr;
    }

    NSMutableDictionary *attachments = [NSMutableDictionary dictionary];
    NSUInteger currentLengthOfContents = 0;
    NSXMLElement *bodyElement = [NSXMLElement elementWithName:@"body"];
    for(GNJEPUBManifestItem *item in epub.spineItems) {
      @autoreleasepool
      {
        NSData *contentDocumentData = [epub dataWithContentsOfFile:item.path];
        if(!contentDocumentData) {
          NSLog(@"cannot read data specified by the path %@.", item.path);
          continue;
        }

        NSUInteger additionalDataLength = 0;
        NSXMLNode *contentDocumentNode = nil;
        NSString *mediaType = item.mediaType;
        if([mediaType isEqualToString:@"application/xhtml+xml"] ||
           [mediaType isEqualToString:@"application/xml"] ||
           [mediaType isEqualToString:@"text/html"]) {
          NSString *basePath = [item.path stringByDeletingLastPathComponent];
          contentDocumentNode = generateDivElementOfXHTMLContentDocument(preview, contentDocumentData, epub, basePath, attachments, &additionalDataLength);
        }
        else if([mediaType hasPrefix:@"image/"]) {
          contentDocumentNode = generateDivElementOfImageContentDocument(item.path);
          NSDictionary *attachment = @{(__bridge NSString *)kQLPreviewPropertyMIMETypeKey: item.mediaType,
                                       (__bridge NSString *)kQLPreviewPropertyAttachmentDataKey: contentDocumentData};
          attachments[item.path] = attachment;
        }

        if(contentDocumentNode) {
          [bodyElement addChild:contentDocumentNode];
          currentLengthOfContents += contentDocumentData.length;
          currentLengthOfContents += additionalDataLength;
        }

        if(QLPreviewRequestIsCancelled(preview)) {
          return noErr;
        }

        if(currentLengthOfContents > kMaxLenghOfContents) {
          break;
        }
      }
    }

    NSXMLNode *charsetAttributeNode = [NSXMLNode attributeWithName:@"charset" stringValue:@"utf-8"];
    NSXMLElement *metaElement = [NSXMLElement elementWithName:@"meta" children:nil attributes:@[charsetAttributeNode]];
    NSXMLElement *styleElement = [NSXMLElement elementWithName:@"style"];
    styleElement.stringValue = [NSString stringWithFormat:
                                @"body { padding: 30px !important; font-size: %@%% !important; }\n"
                                @"p { line-height: 1.5; text-align: justify !important; }\n"
                                @"pre, code { white-space: pre-wrap !important; }\n"
                                @"img { max-height: 95%% !important; max-width: 95%% !important; }",
                                (previewMode == kGNJQLPreviewModeSpotlightPreview) ? @"200" : @"120"];
    NSXMLElement *headElement = [NSXMLElement elementWithName:@"head" children:@[metaElement, styleElement] attributes:nil];
    NSXMLElement *htmlElement = [NSXMLElement elementWithName:@"html" children:@[headElement, bodyElement] attributes:nil];

    NSData *htmlData = [htmlElement.XMLString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[(__bridge NSString *)kQLPreviewPropertyMIMETypeKey] = @"text/html";
    properties[(__bridge NSString *)kQLPreviewPropertyTextEncodingNameKey] = @"UTF-8";
    properties[(__bridge NSString *)kQLPreviewPropertyAttachmentsKey] = attachments;
    NSString *title = [epub.metadata.titles firstObject];
    if(title.length) {
      properties[(__bridge NSString *)kQLPreviewPropertyDisplayNameKey] = title;
    }
    QLPreviewRequestSetDataRepresentation(preview, (__bridge CFDataRef)htmlData, kUTTypeHTML, (__bridge CFDictionaryRef)properties);
  }

  return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
  // Implement only if supported
}


#pragma mark -
#pragma mark Static Functions
static NSXMLElement *generateDivElementOfXHTMLContentDocument(QLPreviewRequestRef preview, NSData *contentDocumentData, GNJEPUB *epub, NSString *basePath, NSMutableDictionary *attachments, NSUInteger *additionalResourceDataLength)
{
  if(!contentDocumentData) {
    return nil;
  }

  NSXMLDocument *contentDocumentXMLDocument = [[NSXMLDocument alloc] initWithData:contentDocumentData options:NSXMLDocumentTidyXML error:NULL];
  if(!contentDocumentXMLDocument) {
    NSLog(@"cannot create NSXMLDocument.");
    return nil;
  }

  NSXMLElement *bodyElement = (NSXMLElement *)[contentDocumentXMLDocument.rootElement gnj_childNodeForLocalName:@"body"];

  NSString *xpath = nil;
  NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];

  if(epub) {
    if(additionalResourceDataLength) {
      *additionalResourceDataLength = 0;
    }

    xpath = @"//*[local-name()='img']/@*[local-name()='src']"
    @"|//*[local-name()='svg']/*[local-name()='image']/@*[local-name()='href']";
    NSArray *referenceAttributeNodes = [bodyElement nodesForXPath:xpath error:NULL];
    for(NSXMLNode *referenceAttributeNode in referenceAttributeNodes) {
      @autoreleasepool {
        NSString *additionalResourcePath = [referenceAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
        additionalResourcePath = [additionalResourcePath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if(!additionalResourcePath.length) {
          continue;
        }

        if(!additionalResourcePath.absolutePath) {
          additionalResourcePath = [basePath stringByAppendingPathComponent:additionalResourcePath];
        }
        additionalResourcePath = [additionalResourcePath gnj_stringByNormalizingPathForZip];

        GNJEPUBManifestItem *item = [epub.manifestItems gnj_itemWithPath:additionalResourcePath];
        NSString *mediaType = item.mediaType;
        if(!mediaType.length) {
          mediaType = [item.path.pathExtension gnj_MIMETypeString];
          if(!mediaType.length) {
            continue;
          }
        }

        NSData *additionalResourceData = [epub dataWithContentsOfFile:additionalResourcePath];
        if(!additionalResourceData) {
          NSLog(@"cannot read data from epub container specified by the path '%@'.", additionalResourcePath);
          continue;
        }

        referenceAttributeNode.stringValue = [NSString stringWithFormat:@"%@:%@", (__bridge NSString *)kQLPreviewContentIDScheme, additionalResourcePath];
        NSDictionary *attachment = @{(__bridge NSString *)kQLPreviewPropertyMIMETypeKey: mediaType,
                                     (__bridge NSString *)kQLPreviewPropertyAttachmentDataKey: additionalResourceData};
        attachments[additionalResourcePath] = attachment;
        if(additionalResourceDataLength) {
          *additionalResourceDataLength += additionalResourceData.length;
          if(*additionalResourceDataLength > kMaxLenghOfContents) {
            break;
          }
        }

        if(preview && QLPreviewRequestIsCancelled(preview)) {
          return nil;
        }
      }
    }
  }

  // WebKit が <style scoped> に対応するようになれば、以下のコードブロックが意味を持ってくる。
  // プレヴュー生成全体の手順は、複数の XHTML コンテントドキュメントの <body> 以下を
  // <div> コンテナにして、ひとつの XHTML にまとめる。
  // 各 XHTML をコンテナ化するとき、ファイル内で指定されているスタイル
  //（<style> と <link rel="stylesheet"> の参照先の内容）を、
  // ひとつの <style scoped="scoped"> にまとめてコンテナ先頭に挿入する。
  // <style> に `scoped` 属性が付くと、指定スタイルが親コンテナのみに限定して適用されるようになる。
  // WebKit が対応していない現状では、スタイル指定を単に一箇所にまとめているに過ぎず、
  // さらに各コンテナで指定されたスタイルがプレヴュー全体に適用されてしまう。
  {
    NSMutableString *styleDeclarations = [NSMutableString string];
    xpath = @"//*[local-name()='head']/*[local-name()='link' and @rel='stylesheet']"
    @"|//*[local-name()='style' and not(@scoped)]";
    NSArray *styleRelatedNodes = [contentDocumentXMLDocument nodesForXPath:xpath error:NULL];
    for(NSXMLNode *styleRelatedNode in styleRelatedNodes) {
      NSString *nodeName = styleRelatedNode.localName;
      if([nodeName isEqualToString:@"style"]) {
        [styleDeclarations appendString:styleRelatedNode.stringValue];
      }
      else if([nodeName isEqualToString:@"link"] && epub) {
        NSXMLNode *hrefAttributeNode = [styleRelatedNode gnj_attributeNodeForLocalName:@"href"];
        NSString *cssPath = [hrefAttributeNode.stringValue stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
        cssPath = [cssPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if(!cssPath.length) {
          continue;
        }
        if(!cssPath.absolutePath) {
          cssPath = [basePath stringByAppendingPathComponent:cssPath];
        }
        NSData *cssData = [epub dataWithContentsOfFile:cssPath];
        if(!cssData) {
          continue;
        }
        NSString *styleDeclaration = [[NSString alloc] initWithData:cssData encoding:NSUTF8StringEncoding];
        [styleDeclarations appendString:styleDeclaration];
      }
    }

    if(styleDeclarations.length) {
      NSXMLNode *scopedAttributeNode = [NSXMLNode attributeWithName:@"scoped" stringValue:@"scoped"];
      NSXMLElement *styleElement = [NSXMLElement elementWithName:@"style" stringValue:styleDeclarations];
      [styleElement addAttribute:scopedAttributeNode];
      [bodyElement insertChild:styleElement atIndex:0];
    }
  }

  bodyElement.name = @"div";
  [bodyElement detach];

  return bodyElement;
}

static NSXMLElement *generateDivElementOfImageContentDocument(NSString *imagePath)
{
  if(!imagePath.length) {
    return nil;
  }

  NSString *path = [NSString stringWithFormat:@"%@:%@", (__bridge NSString *)kQLPreviewContentIDScheme, imagePath];
  NSXMLNode *srcAttributeNode = [NSXMLNode attributeWithName:@"src" stringValue:path];
  NSXMLNode *styleAttributeNode = [NSXMLNode attributeWithName:@"style" stringValue:@"display: block; margin: 15px auto;"];
  NSXMLElement *imgElement = [NSXMLElement elementWithName:@"img" children:nil attributes:@[srcAttributeNode, styleAttributeNode]];

  return [NSXMLElement elementWithName:@"div" children:@[imgElement] attributes:nil];
}

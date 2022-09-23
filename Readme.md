# EPUB Plugins

The EPUB Plugins project contains the OS X Spotlight and Quick Look plugins for EPUBs. By installing these plugins, you can search and preview EPUBs.

## System requirements

macOS 12+

## Download and install plugins

To download plugins, go to [Releases](https://github.com/GenjiApp/EPUB-Plugins/releases) page and click download links in “Downloads” section.

To install plugins, unzip downloaded files and copy them to the following path:

EPUB.mdimporter (Spotlight plugin)

- `~/Library/Spotlight` (only for current user) or
- `/Library/Spotlight` (for all users)

EPUB.qlgenerator (Quick Look plugin)

- `~/Library/QuickLook` (only for current user) or
- `/Library/QuickLook` (for all users)

OS X recognizes these plugins after copying them to appropriate path. However, if the system doesn't recognize the plugins, run commands as follows:

```
$ mdimport -r /path/to/EPUB.mdimorter
$ qlmanage -r
```

or, simply reboot.

## Spotlight importer

The EPUB metadata are assigned to OS X metadata as follows:

| EPUB metadata | OS X metadata   |
| ------------- | --------------- |
| title         | kMDItemTitle    |
| creator       | kMDItemAuthors  |
| subject       | kMDItemKeywords |
| description   | kMDItemDescription, kMDItemHeadline |
| publisher     | kMDItemPublishers, kMDItemOrganizations |
| contributor   | kMDItemContributors |
| identifier    | kMDItemIdentifier |
| language      | kMDItemLanguages |
| coverage      | kMDItemCoverage |
| rights        | kMDItemCopyright, kMDItemRights |
| date          | kMDItemContentCreationDate |
| last modified date | kMDItemContentModificationDate |
| Body text     | kMDItemTextContent |
| Number of content documents in EPUB | kMDItemNumberOfPages |
| EPUB specification version | com_genjiapp_Murasaki_mdimporter_EPUB_EPUBVersion |

## Quick Look generator

| Thumbnail | Preview |
| --------- | ------- |
| Cover image of EPUB | Loading limit: about 1MB

EPUB_CHECK_PATH=/Applications/epubcheck-3.0.1/epubcheck-3.0.1.jar

all: clean
	/bin/mkdir -p "$(TARGET_BUILD_DIR)"
	/usr/bin/zip "$(TARGET_BUILD_DIR)/$(TARGET_NAME).epub" -X -0 mimetype
	/usr/bin/zip "$(TARGET_BUILD_DIR)/$(TARGET_NAME).epub" -r * -x mimetype Makefile \*.DS_Store
	/usr/bin/java -jar "$(EPUB_CHECK_PATH)" "$(TARGET_BUILD_DIR)/$(TARGET_NAME).epub"

clean:
	/bin/rm -f "$(TARGET_BUILD_DIR)/$(TARGET_NAME).epub"
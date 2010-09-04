#!/bin/bash
if [ ! $PROJECT_DIR ]; then
	echo 'import xcode environment from "printenv" target'
    . set_xcode_env.sh
fi

BASE_LOCALE='en'
IBTOOL_FLAGS="--plugin-dir '$BUILD_DIR/$CONFIGURATION$EFFECTIVE_PLATFORM_NAME' --plugin-dir '$PROJECT_DIR/Frameworks'"

L10N_TEMP_DIR="$PROJECT_TEMP_DIR/Localization"
MANUAL_STRINGS_DIR="$PROJECT_DIR/tools/localization/strings"

PO_DIR="$PROJECT_DIR/xchat/po"
PO_STRINGS_DIR="$PROJECT_DIR/tools/localization/po"
MO_BASE_DIR="$PROJECT_DIR/Localization/locale"

XIB_DIR="$PROJECT_DIR/Localization"
XIB_STRINGS_DIR="$L10N_TEMP_DIR/Strings"
BASE_XIB_DIR="$XIB_DIR/$BASE_LOCALE.lproj"
BASE_XIB_STRINGS_DIR="$XIB_STRINGS_DIR/$BASE_LOCALE"

LPROJ_DIR="$XIB_DIR"

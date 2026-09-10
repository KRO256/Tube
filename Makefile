ARCHS = armv7 arm64
TARGET = iphone:clang:12.4:9.0
APPLICATION_NAME = Tube
Tube_FILES = Sources/main.m Sources/AppDelegate.m Sources/YTDLPManager.m Sources/SearchViewController.m Sources/PlayerViewController.m Sources/DownloadManager.m Sources/SettingsViewController.m
Tube_FRAMEWORKS = UIKit Foundation AVFoundation AVKit MediaPlayer
Tube_CFLAGS = -fobjc-arc -Os -Wall -Wno-deprecated-declarations
Tube_LDFLAGS = -dead_strip
INSTALL_TARGET_PROCESSES = Tube

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/application.mk

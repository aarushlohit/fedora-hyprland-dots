pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    function dismiss() {
        GlobalStates.regionSelectorOpen = false
    }

    property var action: RegionSelection.SnipAction.Copy
    property var selectionMode: RegionSelection.SelectionMode.RectCorners

    Timer {
        id: openDelayTimer
        interval: 200
        repeat: false
        property var callback: null
        onTriggered: {
            if (callback) {
                callback();
                callback = null;
            }
        }
    }

    function openRegionSelector(setupAction) {
        if (GlobalStates.regionSelectorOpen) {
            GlobalStates.regionSelectorOpen = false;
        }
        const hadOpen = GlobalStates.overlayOpen || GlobalStates.sidebarRightOpen || 
                        GlobalStates.sidebarLeftOpen || GlobalStates.overviewOpen || 
                        GlobalStates.mediaControlsOpen;
        GlobalStates.overlayOpen = false;
        GlobalStates.sidebarRightOpen = false;
        GlobalStates.sidebarLeftOpen = false;
        GlobalStates.overviewOpen = false;
        GlobalStates.mediaControlsOpen = false;

        if (hadOpen) {
            openDelayTimer.callback = () => {
                setupAction();
                GlobalStates.regionSelectorOpen = true;
            };
            openDelayTimer.restart();
        } else {
            setupAction();
            GlobalStates.regionSelectorOpen = true;
        }
    }
    
    Variants {
        model: Quickshell.screens
        delegate: Loader {
            id: regionSelectorLoader
            required property var modelData
            active: GlobalStates.regionSelectorOpen

            sourceComponent: RegionSelection {
                screen: regionSelectorLoader.modelData
                onDismiss: root.dismiss()
                action: root.action
                selectionMode: root.selectionMode
            }
        }
    }

    function screenshot() {
        openRegionSelector(() => {
            root.action = RegionSelection.SnipAction.Copy;
            root.selectionMode = RegionSelection.SelectionMode.RectCorners;
        });
    }

    function search() {
        openRegionSelector(() => {
            root.action = RegionSelection.SnipAction.Search;
            if (Config.options.search.imageSearch.useCircleSelection) {
                root.selectionMode = RegionSelection.SelectionMode.Circle;
            } else {
                root.selectionMode = RegionSelection.SelectionMode.RectCorners;
            }
        });
    }

    function ocr() {
        openRegionSelector(() => {
            root.action = RegionSelection.SnipAction.CharRecognition;
            root.selectionMode = RegionSelection.SelectionMode.RectCorners;
        });
    }

    function record() {
        if (GlobalStates.regionSelectorOpen) GlobalStates.regionSelectorOpen = false;
        openRegionSelector(() => {
            root.action = RegionSelection.SnipAction.Record;
            root.selectionMode = RegionSelection.SelectionMode.RectCorners;
        });
    }

    function recordWithSound() {
        if (GlobalStates.regionSelectorOpen) GlobalStates.regionSelectorOpen = false;
        openRegionSelector(() => {
            root.action = RegionSelection.SnipAction.RecordWithSound;
            root.selectionMode = RegionSelection.SelectionMode.RectCorners;
        });
    }

    IpcHandler {
        target: "region"

        function dismiss() {
            root.dismiss()
        }
        function screenshot() {
            root.screenshot()
        }
        function search() {
            root.search()
        }
        function ocr() {
            root.ocr()
        }
        function record() {
            root.record()
        }
        function recordWithSound() {
            root.recordWithSound()
        }
    }

    GlobalShortcut {
        name: "regionScreenshot"
        description: "Takes a screenshot of the selected region"
        onPressed: root.screenshot()
    }
    GlobalShortcut {
        name: "regionSearch"
        description: "Searches the selected region"
        onPressed: root.search()
    }
    GlobalShortcut {
        name: "regionOcr"
        description: "Recognizes text in the selected region"
        onPressed: root.ocr()
    }
    GlobalShortcut {
        name: "regionRecord"
        description: "Records the selected region"
        onPressed: root.record()
    }
    GlobalShortcut {
        name: "regionRecordWithSound"
        description: "Records the selected region with sound"
        onPressed: root.recordWithSound()
    }
}

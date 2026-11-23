pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    minimumWidth: 310
    minimumHeight: 130

    Timer {
        id: restoreTimer
        interval: 1500
        repeat: false
        onTriggered: {
            GlobalStates.hideOverlaysForScreenshot = false;
        }
    }

    Timer {
        id: actionDelayTimer
        interval: 350
        repeat: false
        property var action: null
        onTriggered: {
            if (action) {
                action();
                action = null;
            }
        }
    }

    function triggerWithHide(action) {
        GlobalStates.hideOverlaysForScreenshot = true;
        GlobalStates.overlayOpen = false;
        actionDelayTimer.action = () => {
            try {
                action();
            } finally {
                restoreTimer.restart();
            }
        };
        actionDelayTimer.restart();
    }

    contentItem: OverlayBackground {
        id: contentItem
        radius: root.contentRadius
        property real padding: 8
        ColumnLayout {
            id: contentColumn
            anchors.centerIn: parent
            spacing: 10

            Row {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                spacing: 10

                BigRecorderButton {
                    materialSymbol: "screenshot_region"
                    name: "Screenshot region"
                    onClicked: {
                        root.triggerWithHide(() => {
                            Quickshell.execDetached(["/home/aarush/.config/hypr/scripts/ScreenShot.sh", "--area"]);
                        });
                    }
                }

                BigRecorderButton {
                    materialSymbol: "photo_camera"
                    name: "Screenshot"
                    onClicked: {
                        root.triggerWithHide(() => {
                            Quickshell.execDetached(["/home/aarush/.config/hypr/scripts/ScreenShot.sh", "--now"]);
                        });
                    }
                }

                BigRecorderButton {
                    materialSymbol: "screen_record"
                    name: "Record region"
                    onClicked: {
                        root.triggerWithHide(() => {
                            Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "recordWithSound"]);
                        });
                    }
                }
                
                BigRecorderButton {
                    materialSymbol: "capture"
                    name: "Record screen"
                    onClicked: {
                        root.triggerWithHide(() => {
                            Quickshell.execDetached([Directories.recordScriptPath, "--fullscreen", "--sound"]);
                        });
                    }
                }
            }

            RippleButton {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.fillWidth: false
                buttonRadius: height / 2
                colBackground: Appearance.colors.colLayer3
                colBackgroundHover: Appearance.colors.colLayer3Hover
                colRipple: Appearance.colors.colLayer3Active
                onClicked: {
                    GlobalStates.overlayOpen = false;
                    Qt.openUrlExternally(`file://${Config.options.screenRecord.savePath}`);
                }
                contentItem: Row {
                    anchors.centerIn: parent
                    spacing: 6
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "animated_images"
                        iconSize: 20
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("Open recordings folder")
                    }
                }
            }
        }
    }

    component BigRecorderButton: RippleButton {
        id: bigButton
        required property string materialSymbol
        required property string name
        implicitHeight: 66
        implicitWidth: 66
        buttonRadius: height / 2

        colBackground: Appearance.colors.colLayer3
        colBackgroundHover: Appearance.colors.colLayer3Hover
        colRipple: Appearance.colors.colLayer3Active

        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: bigButton.materialSymbol
            iconSize: 28
        }

        StyledToolTip {
            text: bigButton.name
        }
    }
}

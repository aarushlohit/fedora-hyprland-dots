pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Provides access to some Hyprland data not available in Quickshell.Hyprland.
 */
Singleton {
    id: root
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var layers: ({})

    // Convenient stuff

    function toplevelsForWorkspace(workspace) {
        return ToplevelManager.toplevels.values.filter(toplevel => {
            const address = `0x${toplevel.HyprlandToplevel?.address}`;
            var win = HyprlandData.windowByAddress[address];
            return win?.workspace?.id === workspace;
        })
    }

    function hyprlandClientsForWorkspace(workspace) {
        return root.windowList.filter(win => win.workspace.id === workspace);
    }

    function clientForToplevel(toplevel) {
        if (!toplevel || !toplevel.HyprlandToplevel) {
            return null;
        }
        const address = `0x${toplevel?.HyprlandToplevel?.address}`;
        return root.windowByAddress[address];
    }

    function dispatch(cmd) {
        if (!cmd) return;
        cmd = ("" + cmd).trim();
        if (cmd.startsWith("hl.") || cmd.startsWith("return hl.")) {
            Hyprland.dispatch(cmd);
            return;
        }

        let m;
        if ((m = cmd.match(/^movetoworkspacesilent\s+([^,]+),\s*address:(.+)$/))) {
            const ws = m[1].trim();
            const addr = m[2].trim();
            Hyprland.dispatch(`hl.dsp.window.move({ window = 'address:${addr}', workspace = ${isNaN(ws) ? `"${ws}"` : ws}, follow = false })`);
            return;
        }
        if ((m = cmd.match(/^movetoworkspace\s+([^,]+),\s*address:(.+)$/))) {
            const ws = m[1].trim();
            const addr = m[2].trim();
            Hyprland.dispatch(`hl.dsp.window.move({ window = 'address:${addr}', workspace = ${isNaN(ws) ? `"${ws}"` : ws}, follow = true })`);
            return;
        }
        if ((m = cmd.match(/^movetoworkspacesilent\s+(.+)$/))) {
            const ws = m[1].trim();
            Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${isNaN(ws) ? `"${ws}"` : ws}, follow = false })`);
            return;
        }
        if ((m = cmd.match(/^movetoworkspace\s+(.+)$/))) {
            const ws = m[1].trim();
            Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${isNaN(ws) ? `"${ws}"` : ws}, follow = true })`);
            return;
        }
        if ((m = cmd.match(/^workspace\s+(.+)$/))) {
            const ws = m[1].trim();
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${isNaN(ws) ? `"${ws}"` : ws} })`);
            return;
        }
        if ((m = cmd.match(/^focuswindow\s+address:(.+)$/))) {
            const addr = m[1].trim();
            Hyprland.dispatch(`hl.dsp.focus({ window = 'address:${addr}' })`);
            return;
        }
        if ((m = cmd.match(/^closewindow\s+address:(.+)$/))) {
            const addr = m[1].trim();
            Hyprland.dispatch(`hl.dsp.window.close({ window = 'address:${addr}' })`);
            return;
        }
        if ((m = cmd.match(/^pin\s+address:(.+)$/))) {
            const addr = m[1].trim();
            Hyprland.dispatch(`hl.dsp.window.pin({ window = 'address:${addr}' })`);
            return;
        }
        if ((m = cmd.match(/^movewindowpixel\s+exact\s+([0-9.]+)%\s+([0-9.]+)%,\s*address:(.+)$/))) {
            const x = m[1].trim();
            const y = m[2].trim();
            const addr = m[3].trim();
            Hyprland.dispatch(`hl.dsp.window.move({ window = 'address:${addr}', x = '${x}%', y = '${y}%', relative = false })`);
            return;
        }
        if (cmd === "togglespecialworkspace") {
            Hyprland.dispatch('hl.dsp.workspace.toggle_special("")');
            return;
        }
        if (cmd === "reload") {
            Hyprland.dispatch('hl.dsp.reload_config()');
            return;
        }
        if ((m = cmd.match(/^global\s+(.+)$/))) {
            Hyprland.dispatch(`hl.dsp.global("${m[1].trim()}")`);
            return;
        }
        if ((m = cmd.match(/^exec\s+(.+)$/))) {
            const escaped = m[1].trim().replace(/\\/g, "\\\\").replace(/"/g, '\\"');
            Hyprland.dispatch(`hl.dsp.exec_cmd("${escaped}")`);
            return;
        }

        Hyprland.dispatch(cmd);
    }

    // Internals

    function updateWindowList() {
        getClients.running = true;
    }

    function updateLayers() {
        getLayers.running = true;
    }

    function updateMonitors() {
        getMonitors.running = true;
    }

    function updateWorkspaces() {
        getWorkspaces.running = true;
        getActiveWorkspace.running = true;
    }

    function updateAll() {
        updateWindowList();
        updateMonitors();
        updateLayers();
        updateWorkspaces();
    }

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = HyprlandData.windowList.filter(w => w.workspace.id == workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    Component.onCompleted: {
        updateAll();
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            // console.log("Hyprland raw event:", event.name);
            if (["openlayer", "closelayer", "screencast"].includes(event.name)) return;
            updateAll()
        }
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                root.windowList = JSON.parse(clientsCollector.text)
                let tempWinByAddress = {};
                for (var i = 0; i < root.windowList.length; ++i) {
                    var win = root.windowList[i];
                    tempWinByAddress[win.address] = win;
                }
                root.windowByAddress = tempWinByAddress;
                root.addresses = root.windowList.map(win => win.address);
            }
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                root.monitors = JSON.parse(monitorsCollector.text);
            }
        }
    }

    Process {
        id: getLayers
        command: ["hyprctl", "layers", "-j"]
        stdout: StdioCollector {
            id: layersCollector
            onStreamFinished: {
                root.layers = JSON.parse(layersCollector.text);
            }
        }
    }

    Process {
        id: getWorkspaces
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                var rawWorkspaces = JSON.parse(workspacesCollector.text);
                // Filter out invalid workspace ids (e.g. lock-screen temp workspace 2147483647 - N)
                root.workspaces = rawWorkspaces.filter(ws => ws.id >= 1 && ws.id <= 100);
                let tempWorkspaceById = {};
                for (var i = 0; i < root.workspaces.length; ++i) {
                    var ws = root.workspaces[i];
                    tempWorkspaceById[ws.id] = ws;
                }
                root.workspaceById = tempWorkspaceById;
                root.workspaceIds = root.workspaces.map(ws => ws.id);
            }
        }
    }

    Process {
        id: getActiveWorkspace
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            id: activeWorkspaceCollector
            onStreamFinished: {
                root.activeWorkspace = JSON.parse(activeWorkspaceCollector.text);
            }
        }
    }
}

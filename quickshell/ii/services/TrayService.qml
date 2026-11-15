pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    id: root

    property bool smartTray: Config.options.tray.filterPassive
    property list<var> itemsInUserList: SystemTray.items.values.filter(i => (Config.options.tray.pinnedItems.includes(i.id) && (!smartTray || i.status !== Status.Passive)))
    property list<var> itemsNotInUserList: SystemTray.items.values.filter(i => (!Config.options.tray.pinnedItems.includes(i.id) && (!smartTray || i.status !== Status.Passive)))

    property bool invertPins: Config.options.tray.invertPinnedItems
    property list<var> pinnedItems: invertPins ? itemsNotInUserList : itemsInUserList
    property list<var> unpinnedItems: invertPins ? itemsInUserList : itemsNotInUserList

    function getTooltipForItem(item) {
        var result = item.tooltipTitle.length > 0 ? item.tooltipTitle
                : (item.title.length > 0 ? item.title : item.id);
        if (item.tooltipDescription.length > 0) result += " • " + item.tooltipDescription;
        if (Config.options.tray.showItemId) result += "\n[" + item.id + "]";
        return result;
    }

    // Pinning
    function pin(itemId) {
        if (!itemId) return;
        var pins = [...Config.options.tray.pinnedItems];
        if (pins.includes(itemId)) return;
        pins.push(itemId);
        Config.options.tray.pinnedItems = pins;
    }
    function unpin(itemId) {
        if (!itemId) return;
        Config.options.tray.pinnedItems = Config.options.tray.pinnedItems.filter(id => id !== itemId);
    }
    function isPinned(itemId) {
        if (!itemId) return false;
        for (var i = 0; i < root.pinnedItems.length; i++) {
            if (root.pinnedItems[i] && root.pinnedItems[i].id === itemId)
                return true;
        }
        return false;
    }

    function togglePin(itemId) {
        if (!itemId) return;
        if (isPinned(itemId)) {
            // Currently pinned to bar -> unpin it (move to overflow)
            if (root.invertPins) {
                pin(itemId);
            } else {
                unpin(itemId);
            }
        } else {
            // Currently unpinned in overflow -> pin it to bar
            if (root.invertPins) {
                unpin(itemId);
            } else {
                pin(itemId);
            }
        }
    }

}

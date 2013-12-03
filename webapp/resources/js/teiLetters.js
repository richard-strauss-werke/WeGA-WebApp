function switchMenu(obj) {
    var el = document.getElementById(obj);
    if (el.style.display != "none") {
        el.style.display = 'none';
    }
    else {
        el.style.display = '';
    }
}
function $() {
    var elements = new Array();
    for (var i = 0; i < arguments.length; i++) {
        var element = arguments[i];
        if (typeof element == 'string')
        element = document.getElementById(element);
        if (arguments.length == 1)
        return element;
        elements.push(element);
    }
    return elements;
}
function collapseAll(objs) {
    var i;
    for (i = 0; i < objs.length; i++) {
        objs[i].style.display = 'none';
    }
}
function pageLoad() {
    collapseAll($('teiLetter_editorial', 'teiLetter_desc', 'teiLetter_summary'));
}
function addEvent(obj, type, fn) {
    if (obj.addEventListener) {
        obj.addEventListener(type, fn, false);
        EventCache.add(obj, type, fn);
    }
    else if (obj.attachEvent) {
        obj[ "e" + type + fn] = fn;
        obj[type + fn] = function () {
            obj[ "e" + type + fn](window.event);
        }
        obj.attachEvent("on" + type, obj[type + fn]);
        EventCache.add(obj, type, fn);
    }
    else {
        obj[ "on" + type] = obj[ "e" + type + fn];
    }
}

var EventCache = function () {
    var listEvents = [];
    return {
        listEvents : listEvents,
        add : function (node, sEventName, fHandler) {
            listEvents.push(arguments);
        },
        flush : function () {
            var i, item;
            for (i = listEvents.length - 1; i >= 0; i = i - 1) {
                item = listEvents[i];
                if (item[0].removeEventListener) {
                    item[0].removeEventListener(item[1], item[2], item[3]);
                };
                if (item[1].substring(0, 2) != "on") {
                    item[1] = "on" + item[1];
                };
                if (item[0].detachEvent) {
                    item[0].detachEvent(item[1], item[2]);
                };
                item[0][item[1]] = null;
            };
        }
    };
}();
addEvent(window, 'load', pageLoad);
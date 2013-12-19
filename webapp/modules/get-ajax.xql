xquery version "3.0";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

let $ids := tokenize(request:get-parameter('id', ''), '\s+')
return
        <p>ID: {
            for $id in $ids
            return 
                if(config:get-doctype-by-id($id)) then $id
                else ()
        }</p>

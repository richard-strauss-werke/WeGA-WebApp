xquery version "3.0";

import module namespace templates="http://exist-db.org/xquery/templates" at "/db/apps/shared-resources/content/templates.xql";

(: The following modules provide functions which will be called by the templating :)
(:import module namespace i18n="http://exist-db.org/xquery/i18n/templates" at "i18n-templates.xql";:)
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace html="http://xquery.weber-gesamtausgabe.de/modules/html" at "html.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace html-nav="http://xquery.weber-gesamtausgabe.de/modules/html-nav" at "html-nav.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
(:import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";:)
(:import module namespace site="http://exist-db.org/apps/site-utils";:)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

let $config := map {
    $templates:CONFIG_APP_ROOT := $config:app-root
}
let $lookup := function($functionName as xs:string, $arity as xs:int) {
    try {
        function-lookup(xs:QName($functionName), $arity)
    } catch * {
        ()
    }
}
let $content := request:get-data()
return
    templates:apply($content, $lookup, (), $config)
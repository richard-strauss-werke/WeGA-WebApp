xquery version "1.0" encoding "UTF-8";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util = "http://exist-db.org/xquery/util";
declare namespace session = "http://exist-db.org/xquery/session";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets" at "facets.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";

let $text := request:get-parameter('text','')
let $logLevel := request:get-parameter('logLevel','error')
let $errorMessage := 
    if(matches($text, 'filterMenu\.xql')) then ( (: add current filter parameters to the error message:)
        let $docType := substring-after($text, 'docType=')
        let $filter := session:get-attribute(facets:getFilterName($docType))
        let $serializeParameters := 'method=text media-type=text/plain encoding=utf-8'
        return concat($text, '; ', util:serialize($filter, $serializeParameters))
    )
    else $text
let $logToFile := core:logToFile($logLevel, $errorMessage)
return()
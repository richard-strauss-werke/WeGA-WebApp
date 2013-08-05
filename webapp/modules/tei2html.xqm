xquery version "3.0";

(:~
 : XQuery module for transforming TEI to XHTML 
 :)
module namespace tei2html="http://xquery.weber-gesamtausgabe.de/modules/tei2html";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace html-link="http://xquery.weber-gesamtausgabe.de/modules/html-link" at "html-link.xqm";
import module namespace tei2html-namesdates="http://xquery.weber-gesamtausgabe.de/modules/tei2html-namesdates" at "tei2html-namesdates.xqm";
import module namespace tei2html-textstructure="http://xquery.weber-gesamtausgabe.de/modules/tei2html-textstructure" at "tei2html-textstructure.xqm";
(:import module namespace tei2html-textcrit="http://xquery.weber-gesamtausgabe.de/modules/tei2html-textcrit" at "tei2html-textcrit.xqm";:)
(:import module namespace tei2html-linking="http://xquery.weber-gesamtausgabe.de/modules/tei2html-linking" at "tei2html-linking.xqm";:)
(:import module namespace tei2html-core="http://xquery.weber-gesamtausgabe.de/modules/tei2html-core" at "tei2html-core.xqm";:)
(:import module namespace tei2html-header="http://xquery.weber-gesamtausgabe.de/modules/tei2html-header" at "tei2html-header.xqm";:)
(:import module namespace tei2html-figures="http://xquery.weber-gesamtausgabe.de/modules/tei2html-figures" at "tei2html-figures.xqm";:)
(:import module namespace tei2html-transcr="http://xquery.weber-gesamtausgabe.de/modules/tei2html-transcr" at "tei2html-transcr.xqm";:)
(:import module namespace tei2html-wega="http://xquery.weber-gesamtausgabe.de/modules/tei2html-wega" at "tei2html-wega.xqm";:)

declare variable $tei2html:element-from-module := map:new(
    for $module in collection($config:data-collection-path || '/odd')//tei:moduleRef
    group by $key := $module/data(@key)
    return
        for $elem in distinct-values($module/@include/tokenize(., '\s+'))
        return
            map:entry($elem, $key)
);

(:~
 : Main entry function 
 :
 : @author Peter Stadler
 :)
declare function tei2html:process($nodes as node()*, $lang as xs:string) {
    for $node in $nodes
    let $local-name := local-name($node)
    let $func := 
        if($node instance of element()) then 
            try {
                function-lookup(xs:QName("tei2html-" || map:get($tei2html:element-from-module, $local-name) || ':' || $local-name), 2) 
            } catch * {
                ()
            }
        else ()
    return
        if(exists($func) and $func instance of function) then try{$func($node, $lang)} catch * {()}
        else if($node instance of text()) then $node
        else if($node instance of comment()) then tei2html:process-comment($node)
        else tei2html:fallback($node, $lang)
};

declare function tei2html:fallback($node as element(), $lang as xs:string) {
    if($config:isDevelopment) then 
        element xhtml:span {
            attribute class {'not-implemented'},
            tei2html:process($node/node(), $lang)
        }
    else tei2html:process($node/node(), $lang)
};

declare function tei2html:process-comment($node as comment()) {
    ()
};

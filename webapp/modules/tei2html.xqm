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

declare variable $tei2html:serialization-options := 'method=xml media-type=text/html omit-xml-declaration=yes indent=no xinclude-path=' || $config:xsl-collection-path;

(:~
 : Main entry function 
 :
 : @author Peter Stadler
 :)
declare function tei2html:process($nodes as node()*, $options as map()*) {
    let $defaults := map {
        'app-baseHref' := html-link:link-to-current-app(()),    (: External URL :)
        'app-root' := $config:app-root,                         (: Internal database path to the webapp:)
        'data-root' := $config:data-collection-path,            (: Internal database path to the data collections :)
        'optionsFile' := $config:options-file-path,
        'catalogues-collection-path' := $config:catalogues-collection-path
        }
    let $options := 
        if($options) then map:new(($options, $defaults)) 
        else $defaults
    let $options := if(map:contains($options, 'lang')) then () else map:new(($options, map {'lang' := lang:get-set-language('')}))
    let $options := if(map:contains($options, 'transcript')) then () else map:new(($options, map:entry('transcript', 'true')))
    return
        for $node in $nodes
        let $options := if(map:contains($options, 'docID')) then () else map:new(($options, map{'docID' := $node/root()/*/data(@xml:id)}))
        let $docType := config:get-doctype-by-id(map:get($options, 'docID'))
        let $stylesheet := doc($config:xsl-collection-path || '/' || $docType || '.xsl')
        return 
            try { transform:transform($node, $stylesheet, tei2html:create-xslt-options($options)) }
            catch * { core:logToFile('error', 'unable to transform via XSLT') }
    
};

declare %private function tei2html:create-xslt-options($options as map()*) as element(parameters)* {
    <parameters>{
        for $param in map:keys($options)
        return 
            <param name="{$param}" value="{map:get($options, $param)}"/>
    }</parameters>
};

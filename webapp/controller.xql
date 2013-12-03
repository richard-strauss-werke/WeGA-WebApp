xquery version "3.0";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace session="http://exist-db.org/xquery/session";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "modules/controller.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "modules/config.xqm";
import module namespace html-link="http://xquery.weber-gesamtausgabe.de/modules/html-link" at "modules/html-link.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "modules/lang.xqm";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;

let $params := tokenize($exist:path, '/')
let $exist-vars := map {
    'path' := $exist:path,
    'resource' := $exist:resource,
    'controller' := $exist:controller,
    'prefix' := $exist:prefix
    }
let $lang := lang:get-set-language($params[2])
(:let $log := util:log-system-out(
    $params[1]
    (\:'&#10;' || '$exist:path' || ' -- ' || $exist:path || '&#10;' ||
    '$exist:resource' || ' -- ' || $exist:resource || '&#10;':\)
):)

return

if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat(request:get-uri(), '/')}"/>
    </dispatch>

(: 
 :  Startseiten-Weiterleitung 1
 :  Nackte Server-URL (evtl. mit Angabe der Sprache)
:)
else if (matches($exist:path, '^/(en|de)?$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat('de', '/Index')}" />
    </dispatch>

(: 
 :  Startseiten-Weiterleitung 2
 :  Diverse Index Variationen
 :  Achtung: .php hier nicht aufnehmen, dies wird mit den typo3ContentMappings abgefragt
:)
else if (matches($exist:path, '^/[Ii]ndex(\.(htm|html|xml)|/)?$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat($lang, '/Index')}" />
    </dispatch>
 
else if (matches($exist:path, '^/(en/|de/)(Index)?$')) then
    controller:default-forward('index.html', $exist-vars)
    
else if(config:is-person($exist:resource)) then 
    controller:default-forward('person.html', $exist-vars)

else if(config:is-letter($exist:resource)) then 
    controller:default-forward('doc2.html', $exist-vars)
    
else if(config:is-diary($exist:resource)) then 
    controller:default-forward('doc2.html', $exist-vars)

else if(config:is-writing($exist:resource)) then 
    controller:default-forward('doc2.html', $exist-vars)

else if(config:is-news($exist:resource)) then 
    controller:default-forward('doc2.html', $exist-vars)
    
(: Pass all requests to HTML files through view.xql, which handles HTML templating :)
(:else if (ends-with($exist:resource, ".html")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <view>
            <forward url="{$exist:controller}/modules/view.xql">
                <set-attribute name="$exist:prefix" value="{$exist:prefix}"/>
                <set-attribute name="$exist:controller" value="{$exist:controller}"/>
            </forward>
        </view>
        <error-handler>
            <forward url="{$exist:controller}/error-page.html" method="get"/>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </error-handler>
    </dispatch>:)

(:else if (contains($exist:path, "/$shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>:)

(: images, css are contained in the top /resources/ collection. :)
(: Relative path requests from sub-collections are redirected there :)
else if (contains($exist:path, "/resources/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/{substring-after($exist:path, '/resources/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>

else
    <ignore xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </ignore>
    
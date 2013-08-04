xquery version "3.0";

(:~
 : XQuery module for processing dates
 :)
module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace exist="http://exist.sourceforge.net/NS/exist";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";

(:import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";:)

declare function controller:default-forward($html-template as xs:string, $exist-vars as map()*) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{map:get($exist-vars, 'controller') || '/templates/' || $html-template}"/>
    	<view>
            <forward url="{map:get($exist-vars, 'controller') || '/modules/view.xql'}">
                <set-attribute name="$exist:prefix" value="{map:get($exist-vars, 'prefix')}"/>
                <set-attribute name="$exist:controller" value="{map:get($exist-vars, 'controller')}"/>
                <set-attribute name="docID" value="{map:get($exist-vars, 'resource')}"/>
                <set-header name="Cache-Control" value="no-cache"/>
            </forward>
        </view>
        <error-handler>
            <forward url="{map:get($exist-vars, 'controller') || '/templates/error-page.html'}" method="get"/>
            <forward url="{map:get($exist-vars, 'controller') || '/modules/view.xql'}"/>
        </error-handler>
    </dispatch>
};

xquery version "3.0";

(:~
 : XQuery module for generating HTML links
 : (these will be called by the HTML templates)
 :)
module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace session="http://exist-db.org/xquery/session";
(:import module namespace templates="http://exist-db.org/xquery/templates" at "/db/apps/shared-resources/content/templates.xql";:)
(:import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";:)
(:import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";:)
(:import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";:)

(:~
 : get and set language variable from/in a session attribute
 :
 : @author Peter Stadler
 : @param $lang the language to set
 : @return xs:string the (newly) set language variable 
 :)
declare function lang:get-set-language($lang as xs:string?) as xs:string {
    let $defaultLang := 'de'
    let $setLang := 
        if(matches($lang, 'de|en')) then session:set-attribute('lang', $lang)
        else ()
    let $getLang := session:get-attribute('lang')
    return 
         if(matches($getLang, 'de|en')) then $getLang
         else $defaultLang
};

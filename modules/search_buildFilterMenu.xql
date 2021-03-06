xquery version "1.0" encoding "UTF-8";
(:declare default element namespace "http://www.w3.org/1999/xhtml";:) 
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/modules/xho" at "xho.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets" at "facets.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"; 

declare function local:buildFilterList($lang,$coll,$name,$heading) {
    (
    <h2>{$heading}</h2>,
    <ul>
    {
       for $item in subsequence($coll,1,6)
       return
          <li>
              <input type="checkbox" name="{$name}" value="{$item//facets:term}"/><label onclick="applySearchFilter('{$lang}','{()}')"><a>{$item//facets:term}</a></label><span>{concat(' (',$item//facets:frequency,')')}</span>
          </li>
    }
    </ul>,
    <a style="cursor:pointer" onclick="selectAllInputs('{$name}')">{lang:get-language-string('selectAll',$lang)}</a>,
    <input type="submit" class="search-button" title="{lang:get-language-string('apply',$lang)}" value="{lang:get-language-string('apply',$lang)}"/>
    )
};

declare function local:buildFilterMenu($lang,$searchResults) {
    let $settlements := facets:createFacets($searchResults//tei:settlement)
    let $occupations := facets:createFacets($searchResults//tei:occupation)
    
    return 
    (
        local:buildFilterList($lang,$settlements,'settlementsSelect','Orte'),
        local:buildFilterList($lang,$occupations,'occupationsSelect','Tätigkeiten')
    )
        
};

let $lang          := request:get-parameter('lang','de')
let $searchResults := session:get-attribute(config:get-option('searchSessionName'))
(:let $log := util:log-system-out():)

return local:buildFilterMenu($lang,$searchResults)
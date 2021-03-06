xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace session="http://exist-db.org/xquery/session";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace cache="http://exist-db.org/xquery/cache";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/modules/xho" at "xho.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets" at "facets.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"; 

let $category := request:get-parameter('category','sender')
let $docType := request:get-parameter('docType','letters')
let $cacheKey := request:get-parameter('cacheKey','indices')
let $checked := session:get-attribute('checked')
let $lang := lang:get-set-language(())
let $categoryList := session:get-attribute('facetCategories')//facets:entry/string(@xml:id)

return
    <div style="border: 2px solid #AAAAAA; height: 99%">
        <h2>{lang:get-language-string("restrictSelection", $lang)}</h2>
        <ul id="popupTabs" class="shadetabs">
            {
               for $cat in $categoryList
               return
                <li onmouseover="this.style.cursor='pointer'" onclick="clickOnPopupTab(this,'{$cat}');">
                    <a title="{lang:get-language-string($cat, $lang)}" class="{if($category eq $cat) then 'selected' else()}">{lang:get-language-string($cat, $lang)}</a>
                </li>
            }
        </ul>
        {
        <div id="popupContent" style="text-align:left; position:relative; border: 2px solid #AAAAAA; margin: 0 5px; overflow:auto;">
            {
            for $x in $categoryList return
                <div id="popupContent_{$x}" style="display:{if($x=$category) then 'block' else 'none'}">{
                    let $facets := session:get-attribute(concat('facetsSessionAttribute_', $docType,$x)) (: von serverseitigem cache zu client attribute geändert, da sich sonst verschiedene clients beeinflussen können (PS) :)
                        (:cache:get('facets',concat($docType,$x)):)
                    (:let $log := util:log-system-out(concat('popup - ', concat('facetsSessionAttribute_', $docType,$x), ': ', count($facets))):)
                    return facets:createFacetListForPopup($facets, $x, $docType, $lang)
                }</div>
            }
        </div>
        }
        <h3 style="bottom:0px; position:absolute; text-align:center; width:100%">
            
            <span style="margin-right:100px" onmouseover="this.style.cursor='pointer'" onclick="this.parentNode.parentNode.parentNode.style.visibility='hidden';document.getElementById('overlay').style.display='none';">{lang:get-language-string("cancel", $lang)}</span>
            <!--<span onmouseover="this.style.cursor='pointer'">{lang:get-language-string("reset", $lang)} </span>-->
            <span onmouseover="this.style.cursor='pointer'" onclick="applyFilter(document.getElementById('popupTabs').firstChild,'{$docType}','{$cacheKey}','{$lang}');document.getElementById('overlay').style.display='none';">{lang:get-language-string("confirm", $lang)}</span>
            
        </h3>
    </div>
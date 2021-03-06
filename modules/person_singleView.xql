xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";

import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/modules/xho" at "xho.xqm";
import module namespace functx="http://www.functx.com";
import module namespace ajax="http://xquery.weber-gesamtausgabe.de/modules/ajax" at "ajax.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";

declare function local:collectMetaData($person as document-node(), $lang as xs:string) as element(wega:metaData) {
    let $personID := $person/tei:person/string(@xml:id)
    let $name := wega:printFornameSurname($person//tei:persName[@type='reg'])
    let $pageTitle := concat($name, ' – ', lang:get-language-string('tabTitle_bio', $lang)) 
    let $pnd_dates := concat(date:printDate($person//tei:birth/tei:date[1],$lang), '–', date:printDate($person//tei:death/tei:date[1],$lang))
    let $occupations := string-join($person//tei:occupation/normalize-space(), ', ')
    let $placesOfAction := string-join($person//tei:residence/normalize-space(), ', ')
    let $pageDescription := concat(
        lang:get-language-string('bioInfoAbout', $lang), ' ', 
        $name,'. ',
        lang:get-language-string('pnd_dates', $lang), ': ', 
        $pnd_dates, '. ',
        lang:get-language-string('occupations', $lang), ': ',
        $occupations, '. ',
        lang:get-language-string('placesOfAction', $lang), ': ', 
        $placesOfAction
    )
    let $commonMetaData := xho:collectCommonMetaData($person)
    let $noimageindex := if(exists(collection('/db/iconography')//tei:figure[.//tei:person[@corresp = $personID]][@n = 'portrait'][1][./tei:graphic])) then () else <meta name="robots" content="noimageindex"/>
    return 
    <wega:metaData>
        <title>{$pageTitle}</title>
        {$commonMetaData/*}
        <meta name="DC.title" content="{$pageTitle}"/>
        <meta name="description" content="{$pageDescription}" lang="{$lang}"/>
        <meta name="DC.description" content="{$pageDescription}"/>
        <meta name="DC.subject" content="{lang:get-language-string('bio', $lang)}"/>
        <!-- <meta name="DC.source" content=""/> -->
        <!-- <meta name="DC.relation" content=""/> --> 
        <!-- <meta name="DC.coverage" content="" scheme="DCTERMS.TGN"/> -->
        <meta name="DC.language" content="de" scheme="DCTERMS.RFC3066"/>
        <meta name="DC.rights" content="http://creativecommons.org/licenses/by-nc-sa/3.0/" scheme="DCTERMS.URI"/>
        {$noimageindex}
    </wega:metaData>
};

let $lang := request:get-parameter('lang','')
let $id := request:get-parameter('id','A002068')
let $withJS := request:get-parameter('js','true')
let $person := core:doc($id)
let $name := wega:cleanString($person//tei:persName[@type='reg'])
let $pnd := $person//tei:idno[@type='gnd']
let $xslParams := config:get-xsl-params(()) 
let $domLoaded := 
    if($withJS eq 'true') then
    <domLoaded xmlns="">
        <function>
            <name>requestPersonMetaData</name>
            <param>{$id}</param>
            <param>{$lang}</param>
        </function>
        <function>
            <name>requestPersonCorrespondents</name>
            <param>{$id}</param>
            <param>{$lang}</param>
            <param>contacts</param>
            <param>all</param>
        </function>
        <function>
            <name>requestPersonIconography</name>
            <param>{$id}</param>
            <param>{string($pnd)}</param>
            <param>{$lang}</param>
        </function>
    </domLoaded>
    else()
return 
<html>
    {xho:createHtmlHead(('person_singleView.css', 'xmlPrettyPrint.css'), 'person_functions.js', local:collectMetaData($person, $lang), $domLoaded, ())}
    <body>
        <div id="container">
            {xho:createHeadContainer($lang)}
            <div id="main">
                <div id="contentLeft">
                    <div id="personSummary"><!-- (:Wird onload durch getPersonMetaData() gefüllt &#63;function=getMetaData&#38;lang=',$lang:) -->
                    {if($withJS ne 'true') then wega:getDocumentMetaData($id,$lang,'singleView') else()}
                    </div>
                    <ul id="personTabs" class="shadetabs">
                        <li><a href="functions/getAjax.xql?function=getBiography&#38;id={$id}&#38;lang={$lang}" class="selected" rel="personDetails" title="{lang:get-language-string('tabTitle_bio',$lang)}">{lang:get-language-string('bio',$lang)}</a></li>
                        <li><a href="functions/xmlPrettyPrint.xql?id={$id}" rel="personDetails" title="{lang:get-language-string('tabTitle_xml', $lang)}">XML</a></li>
                        <li>
                            {if(exists($pnd)) then <a href="functions/getAjax.xql?function=getWikipedia&#38;pnd={string($pnd)}&#38;lang={$lang}" rel="personDetails" title="{lang:get-language-string('tabTitle_wikipedia', $lang)}">Wikipedia</a>
                                else <span class="notAvailable">Wikipedia</span>}
                        </li>
                        <li>
                            {if(exists($pnd)) then <a href="functions/getAjax.xql?function=getDNB&#38;pnd={string($pnd)}&#38;lang={$lang}" rel="personDetails" title="{lang:get-language-string('tabTitle_pnd', $lang)}">DNB</a>
                                else <span class="notAvailable">DNB</span>}
                        </li>
                        <li>
                            {if(exists($pnd)) then <a href="functions/getAjax.xql?function=getADB&#38;pnd={string($pnd)}&#38;lang={$lang}" rel="personDetails" title="{lang:get-language-string('tabTitle_ADB', $lang)}">ADB</a>
                                else <span class="notAvailable">ADB</span>}
                        </li>
                        <li>
                            {if(exists($pnd)) then <a href="functions/getAjax.xql?function=getPNDBeacons&#38;pnd={string($pnd)}&#38;lang={$lang}&#38;name={encode-for-uri($name)}" rel="personDetails" title="{lang:get-language-string('tabTitle_Redirects', $lang)}">PND-Beacon</a>
                                else <span class="notAvailable">PND-Beacon</span>}
                        </li>
                        <!--<li><a href="functions/person_getBacklinks.xql?id={$id}&#38;lang={$lang}" rel="personDetails" title="{lang:get-language-string('tabTitle_backlinks', $lang)}">{lang:get-language-string('backlinks',$lang)}</a></li>-->
                    </ul>
                    <div id="personDetails">
                        <!--(:Wird durch ajaxTabs gefüllt:)-->
                        {if($withJS ne 'true') then ajax:getBiography($id,$lang) else()}
                    </div>
                    <script type="text/javascript">
                        var personTabs=new ddajaxtabs("personTabs", "personDetails")
                        personTabs.setpersist(true)
                        personTabs.setselectedClassTarget("link")
                        if('{$withJS}'=='true') personTabs.init()                        
                    </script>
                </div>
                
                <div id="contentRight">
                    <div>
                        <h2>{lang:get-language-string('contacts',$lang)}</h2>
                        <div id="contacts">
                        <!-- (:Wird onload durch requestPersonCorrespondents() gefüllt:) -->
                        {if($withJS ne 'true') then ajax:getPersonCorrespondents($id,$lang,'0001-01-01','9999-01-01','all') else()}
                        </div>
                    </div>
                    <div id="iconography">
                        <h2>{lang:get-language-string('album',$lang)}</h2>
                        <!-- (:Wird onload durch requestPersonIconography() appended:) -->
                        {if($withJS ne 'true') then ajax:getIconography($id,string($pnd),$lang) else()}
                    </div>
                    {if($person//tei:affiliation/tei:address) then 
                        <div id="sidebarAddress">
                            <h2>{lang:get-language-string('address',$lang)}</h2>
                            {wega:outputAddress(
                                $person//tei:affiliation/tei:address, 
                                $lang,
                                normalize-space(string-join(reverse(tokenize($name, ',')), ' ')))}
                        </div>
                    else ()}
                    {xho:createWorksDocumentsUL($id, $lang)}
                </div>
            </div>
            {xho:createFooter($lang, document-uri($person))}
        </div>
    </body>
</html>

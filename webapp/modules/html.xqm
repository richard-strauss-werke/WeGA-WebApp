xquery version "3.0";

(:~
 : XQuery module for generating HTML fragments
 : (these will be called by the HTML templates)
 :)
module namespace html="http://xquery.weber-gesamtausgabe.de/modules/html";

(:declare namespace repo="http://exist-db.org/xquery/repo";:)
(:declare namespace expath="http://expath.org/ns/pkg";:)
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";

declare %templates:wrap function html:page-title($node as node(), $model as map(*)) as xs:string {
    ''
};

(:declare function html:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};:)

(:~
 : Top navigation for all pages 
 :
 : @author Peter Stadler
 : @return html:div 
 :)
declare function html:page-top-bar-section($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:section) {
    let $html_pixDir := config:get-option('pixDir')
    let $baseHref := config:get-option('baseHref')
    let $uriTokens := tokenize(xmldb:decode-uri(request:get-uri()), '/')
    let $search := string-join(($baseHref, $lang, core:getLanguageString('search', $lang)), '/')
    let $index := string-join(($baseHref, $lang, core:getLanguageString('index', $lang)), '/')
    let $impressum := string-join(($baseHref, $lang, core:getLanguageString('about', $lang)), '/')
    let $help := string-join(($baseHref, $lang, core:getLanguageString('help', $lang)), '/')
    let $switchLanguage := 
        for $i in $uriTokens[string-length(.) gt 2]
        return
        if (matches($i, 'A\d{6}'))
            then $i
            else if($lang eq 'en') 
                then replace(core:translateLanguageString(replace($i, '_', ' '), $lang, 'de'), '\s', '_') (: Ersetzen von Leerzeichen durch Unterstriche in der URL :)
                else replace(core:translateLanguageString(replace($i, '_', ' '), $lang, 'en'), '\s', '_')
    let $switchLanguage := if($lang eq 'en')
        then <a href="{string-join(($baseHref, 'de', $switchLanguage), '/')}" title="Diese Seite auf Deutsch"><img src="{string-join(($baseHref, $html_pixDir, 'de.gif'), '/')}" alt="germanFlag" width="20" height="12"/></a>
        else <a href="{string-join(($baseHref, 'en', $switchLanguage), '/')}" title="This page in english"><img src="{string-join(($baseHref, $html_pixDir, 'gb.gif'), '/')}" alt="englishFlag" width="20" height="12"/></a>
    return 
    element section {
        attribute class {"top-bar-section"},
        (:if(config:get-option('environment') eq 'development') then attribute class {'dev'}
        else if(config:get-option('environment') eq 'release') then attribute class {'rel'}
        else (),
        <h1><a href="{$index}"><span class="hiddenLink">Carl Maria von Weber Gesamtausgabe</span></a></h1>,:)
        <ul class="left">
            <li class="has-form">
                <form>
                    <div class="row collapse">
                        <div class="small-8 columns">
                            <input type="text"/>
                        </div>
                        <div class="small-4 columns">
                            <a href="#" class="small button">Search</a>
                        </div>
                    </div>
                </form>
            </li>
        </ul>,
        <ul class="right">
            <li><a href="{$index}">{core:getLanguageString('home',$lang)}</a></li>
            <li class="divider"></li>
            <li><a href="{$impressum}">{core:getLanguageString('about',$lang)}</a></li>
            <li class="divider"></li>
            <li><a href="{$help}">{core:getLanguageString('help',$lang)}</a></li>
            <li class="divider"></li>
            <li>{$switchLanguage}</li>
        </ul>
    }
};

(:~
 : Sub navigation for the index and error pages 
 :
 : @author Peter Stadler
 : @return html:div 
 :)
declare function html:page-nav-digital-edition($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    <div id="page-nav-digital-edition" xmlns="http://www.w3.org/1999/xhtml">
        <h3>{core:getLanguageString('digitalEdition', $lang)}</h3>
        <ul>
            <li><a href="{$config:app-root || '/A002068'}">Weber Person</a></li>
            <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('correspondence', $lang)), '/')}">Weber {core:getLanguageString('correspondence', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('diaries', $lang)), '/')}">Weber {core:getLanguageString('diaries', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('writings', $lang)), '/')}">Weber {core:getLanguageString('writings', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('works', $lang)), '/')}">Weber {core:getLanguageString('works', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('indices', $lang)), '/')}">{core:getLanguageString('indices', $lang)}</a></li>
        </ul>
    </div>
};

(:~
 : Sub navigation for the index and error pages
 :
 : @author Peter Stadler
 : @return html:div 
 :)
declare function html:page-nav-project-links($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    <div id="page-nav-project-links" xmlns="http://www.w3.org/1999/xhtml">
        <h3>{core:getLanguageString('aboutTheProject', $lang)}</h3>
        <ul>
            <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('indices',$lang), core:getLanguageString('news',$lang)),'/')}">{core:getLanguageString('news', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, replace(core:getLanguageString('editorialGuidelines',$lang), '\s', '_')),'/')}">{core:getLanguageString('editorialGuidelines', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, replace(core:getLanguageString('projectDescription',$lang), '\s', '_')), '/')}">{core:getLanguageString('projectDescription', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('publications',$lang)), '/')}">{core:getLanguageString('publications', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('bibliography',$lang)), '/')}">{core:getLanguageString('bibliography', $lang)}</a></li>
            <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('contact',$lang)), '/')}">{core:getLanguageString('contact', $lang)}</a></li>
        </ul>
    </div>
};


(:~
 : Sub navigation for the index and error pages
 :
 : @author Peter Stadler
 : @return html:div 
 :)
declare function html:page-nav-dev-links($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    <div id="page-nav-dev-links" xmlns="http://www.w3.org/1999/xhtml">{
        element h3 {core:getLanguageString('development', $lang)},
        element ul {
            element li {
                element a {
                    attribute href {string-join(($config:app-root, $lang, core:getLanguageString('tools', $lang)), '/')},
                    'Tools'
                }
            }
        }
    }
    </div>
};

declare function html:page-nav-combined($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    <div class="section-container accordion" data-section="" data-options="one_up: false;" xmlns="http://www.w3.org/1999/xhtml">
        <section class="section">
            <p class="title" data-section-title=""><a href="#">{core:getLanguageString('digitalEdition', $lang)}</a></p>
            <div class="content" data-section-content="">
                <ul class="side-nav">
                    <li><a href="{$config:app-root || '/A002068'}">Weber Person</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('correspondence', $lang)), '/')}">Weber {core:getLanguageString('correspondence', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('diaries', $lang)), '/')}">Weber {core:getLanguageString('diaries', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('writings', $lang)), '/')}">Weber {core:getLanguageString('writings', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, 'A002068', core:getLanguageString('works', $lang)), '/')}">Weber {core:getLanguageString('works', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('indices', $lang)), '/')}">{core:getLanguageString('indices', $lang)}</a></li>
                </ul>
            </div>
        </section>
        <section class="section">
            <p class="title" data-section-title=""><a href="#">{core:getLanguageString('aboutTheProject', $lang)}</a></p>
            <div class="content" data-section-content="">
                <ul class="side-nav">
                    <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('indices',$lang), core:getLanguageString('news',$lang)),'/')}">{core:getLanguageString('news', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, replace(core:getLanguageString('editorialGuidelines',$lang), '\s', '_')),'/')}">{core:getLanguageString('editorialGuidelines', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, replace(core:getLanguageString('projectDescription',$lang), '\s', '_')), '/')}">{core:getLanguageString('projectDescription', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('bibliography',$lang)), '/')}">{core:getLanguageString('bibliography', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('publications',$lang)), '/')}">{core:getLanguageString('publications', $lang)}</a></li>
                    <li><a href="{string-join(($config:app-root, $lang, core:getLanguageString('contact',$lang)), '/')}">{core:getLanguageString('contact', $lang)}</a></li>
                </ul>
            </div>
        </section>
    </div>
};

declare function html:print-latest-news($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    let $latestNews := query:get-latest-news(())
    return
        <div xmlns="http://www.w3.org/1999/xhtml">
            <h2>{core:getLanguageString('news', $lang)}</h2>
            {for $news at $count in $latestNews
                let $newsTeaserDate := $news//tei:fileDesc//tei:date/xs:dateTime(@when)
                let $authorID := data($news//tei:titleStmt/tei:author[1]/@key)
                let $dateFormat := 
                    if ($lang = 'en') then '%A, %B %d, %Y'
                    else '%A, %d. %B %Y'
                return (
                    element span {
                        attribute class {'newsTeaserDate'},
                        core:getLanguageString('websiteNews', date:strfdate($dateFormat, datetime:date-from-dateTime($newsTeaserDate), $lang), $lang)
                    },
                    element h2 {
                        element a {
                            attribute href {html:createLinkToDoc($news, $lang)},
                            attribute title {string($news//tei:title[@level='a'])},
                            string($news//tei:title[@level='a'])
                        }
                    },
                    element p {
                        substring($news//tei:body, 1, 400),
                        ' … ',
                        element a{
                            attribute href {html:createLinkToDoc($news, $lang)},
                            attribute title {core:getLanguageString('more', $lang)},
                            attribute class {'readOn'},
                            concat('[', core:getLanguageString('more', $lang), ']')
                        }
                    },
                    if($count ne count($latestNews)) then <hr class="news-teaser-break"/>
                    else ()
                )
            }
        </div>
};

declare function html:print-todays-events($node as node(), $model as map(*), $date as xs:date?, $lang as xs:string) as element(xhtml:div) {
    let $date := 
        if(exists($date)) then $date
        else current-date()
    let $todaysEventsFileName := concat('todaysEventsFile_', $lang, '.xml')
    let $todaysEventsFile := doc(string-join(($config:tmp, $todaysEventsFileName), '/'))
    return 
        if(false() and xmldb:last-modified($config:tmp, $todaysEventsFileName) cast as xs:date eq current-date() and xmldb:last-modified($config:tmp, $todaysEventsFileName) gt config:getDateTimeOfLastDBUpdate()) then $todaysEventsFile/xhtml:div
        else 
            let $output := 
                <div xmlns="http://www.w3.org/1999/xhtml" id="todays-events">
                    <h3>{core:getLanguageString('whatHappenedOn', date:strfdate(if($lang eq 'en') then '%B %d' else '%d. %B', $date, $lang), $lang)}</h3>
                    <ul>
                    {for $i in query:get-todays-events($date)
                        let $isJubilee := (year-from-date($date) - $i/year-from-date(@when)) mod 25 = 0
                        let $typeOfEvent := 
                            if($i/ancestor::tei:correspDesc) then 'letter'
                            else if($i/parent::tei:birth[@type='baptism']) then 'isBaptised'
                            else if($i/parent::tei:birth) then 'isBorn'
                            else if($i/parent::tei:death[@type='funeral']) then 'wasBuried'
                            else if($i/parent::tei:death) then 'dies'
                            else ()
                        order by $i/xs:date(@when) ascending
                        return 
                            element li {
                                if($isJubilee) then attribute class {'jubilee'} else (),
                                date:formatYear(year-from-date($i/@when) cast as xs:int, $lang) || ': ', 
                                if($typeOfEvent eq 'letter') then (
                                    html:printCorrespondentName($i/ancestor::tei:correspDesc/tei:sender[1]/*[1], $lang, 'fs'), ' ',
                                    core:getLanguageString('writesTo', $lang), ' ',
                                    html:printCorrespondentName($i/ancestor::tei:correspDesc/tei:addressee[1]/*[1], $lang, 'fs'), ' '
                                )
                                else $i/root()/*/@xml:id/string()
                            }
                    }
                    </ul>
                </div>
            return doc(core:store-file($config:tmp, $todaysEventsFileName, $output))/xhtml:div
(:            $output:)
};

(:~
 : Construct a name from a persName or name element wrapped in a <span> with @onmouseover etc.
 : If a @key is given on persName the regularized form will be returned, otherwise the content of persName.
 : If persName is empty than "unknown" is returned.
 : 
 : @author Peter Stadler
 : @param $persName the tei:persName element
 : @param $lang the current language (de|en)
 : @param $order (sf|fs) whether to print "surname, forename" or "forename surname"
 : @return 
 :)
declare function html:printCorrespondentName($persName as element(), $lang as xs:string, $order as xs:string) as element() {
     if(exists($persName/@key)) 
        then html:createPersonLink($persName/string(@key), $lang, $order)
        else if (exists($persName//text())) 
            then <span class="noDataFound">{normalize-space($persName)}</span>
            else <span class="noDataFound">{core:getLanguageString('unknown',$lang)}</span>
};

(:~
 : Creates person link
 :
 : @author Peter Stadler
 : @param $id of the person
 : @param $lang the current language (de|en)
 : @param $order (sf|fs) whether to print "surname, forename" or "forename surname"
 : @return HTML element
 :)
declare function html:createPersonLink($id as xs:string, $lang as xs:string, $order as xs:string) as element() {
    let $name := 
        if($order eq 'fs') then core:printFornameSurname(query:getRegName($id))
        else query:getRegName($id)
    return 
        if($name != '') then 
            <a href="{string-join(($config:app-root, $lang, $id), '/')}">
                <span class="person" onmouseover="metaDataToTip('{$id}', '{$lang}')" onmouseout="UnTip()">{$name}</span>
            </a>
        else <span class="{concat('noDataFound ', $id)}">{core:getLanguageString('unknown',$lang)}</span>
};

(:~
 : Creates document link
 :
 : @author Peter Stadler
 : @param $doc the document to create the link for
 : @param $content the string content for the xhtml a element
 : @param $lang the language switch (en, de)
 : @param $attributes a sequence of attribute-value-pairs, e.g. ('class=xy', 'style=display:block')
 :)
declare function html:createDocLink($doc as document-node(), $content as xs:string, $lang as xs:string, $attributes as xs:string*) as element() {
    let $href := html:createLinkToDoc($doc, $lang)
    let $docID :=  $doc/root()/*/@xml:id
    return 
    element a {
        attribute href {$href},
        attribute onmouseover {concat("metaDataToTip('", $docID, "','", $lang, "')")},
        attribute onmouseout {'UnTip()'},
        if(exists($attributes)) then for $att in $attributes return attribute {substring-before($att, '=')} {substring-after($att, '=')} 
        else (),
        $content
    }
};

(:~
 : Creates link to doc
 :
 : @author Peter Stadler
 : @param $doc document node
 : @param $lang the current language (de|en)
 : @return xs:string
:)
declare function html:createLinkToDoc($doc as document-node(), $lang as xs:string) as xs:string? {
    let $docID :=  $doc/*/@xml:id cast as xs:string
    let $authorId := query:getAuthorOfTeiDoc($doc)
    let $folder := 
        if(config:isLetter($docID)) then core:getLanguageString('correspondence', $lang) (: Ausnahme für Briefe=Korrespondenz:)
        else if(config:isWeberStudies($doc)) then core:getLanguageString('weberStudies', $lang)
        else core:getLanguageString(config:getDoctypeByID($docID), $lang)
    return 
        if(config:isPerson($docID)) then string-join(($config:app-root, $lang, $docID), '/') (: Ausnahme für Personen, die direkt unter {baseref}/{lang}/ angezeigt werden:)
        else if(config:isBiblio($docID)) then 
            if(config:isWeberStudies($doc)) then string-join(($config:app-root, $lang, core:getLanguageString('publications', $lang), $folder, $docID), '/')
            else ()
        else if(exists($folder) and $authorId ne '') then string-join(($config:app-root, $lang, $authorId, $folder, $docID), '/')
        else ()
};

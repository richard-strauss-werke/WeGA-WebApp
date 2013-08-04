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

import module namespace templates="http://exist-db.org/xquery/templates" at "/db/apps/shared-resources/content/templates.xql";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";
import module namespace html-link="http://xquery.weber-gesamtausgabe.de/modules/html-link" at "html-link.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace functx="http://www.functx.com" at "functx.xqm";

declare %templates:wrap function html:page-title($node as node(), $model as map(*)) as xs:string {
    ''
};

(:declare function html:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};:)

declare function html:print-latest-news($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    let $latestNews := query:get-latest-news(())
    return
        <div xmlns="http://www.w3.org/1999/xhtml">
            <h2>{lang:get-language-string('news', $lang)}</h2>
            {for $news at $count in $latestNews
                let $newsTeaserDate := $news//tei:fileDesc//tei:date/xs:dateTime(@when)
                let $authorID := data($news//tei:titleStmt/tei:author[1]/@key)
                let $dateFormat := 
                    if ($lang = 'en') then '%A, %B %d, %Y'
                    else '%A, %d. %B %Y'
                return (
                    element span {
                        attribute class {'newsTeaserDate'},
                        lang:get-language-string('websiteNews', date:strfdate($dateFormat, datetime:date-from-dateTime($newsTeaserDate), $lang), $lang)
                    },
                    element h2 {
                        element a {
                            attribute href {html-link:create-href-for-doc($news, $lang)},
                            attribute title {string($news//tei:title[@level='a'])},
                            string($news//tei:title[@level='a'])
                        }
                    },
                    element p {
                        substring($news//tei:body, 1, 400),
                        ' … ',
                        element a{
                            attribute href {html-link:create-href-for-doc($news, $lang)},
                            attribute title {lang:get-language-string('more', $lang)},
                            attribute class {'readOn'},
                            concat('[', lang:get-language-string('more', $lang), ']')
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
    let $todaysEventsFile := doc(string-join(($config:tmp-collection-path, $todaysEventsFileName), '/'))
   (: let $log := util:log-system-out(
        for $i in request:attribute-names()
        return $i || ' -- ' || request:get-attribute($i)
        ):)
    return 
        if((:false() and:) xmldb:last-modified($config:tmp-collection-path, $todaysEventsFileName) cast as xs:date eq current-date() and xmldb:last-modified($config:tmp-collection-path, $todaysEventsFileName) gt config:getDateTimeOfLastDBUpdate()) then $todaysEventsFile/xhtml:div
        else 
            let $output := 
                <div xmlns="http://www.w3.org/1999/xhtml" id="todays-events">
                    <h3>{lang:get-language-string('whatHappenedOn', date:strfdate(if($lang eq 'en') then '%B %d' else '%d. %B', $date, $lang), $lang)}</h3>
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
                                    let $sender := html:print-persname($i/ancestor::tei:correspDesc/tei:sender[1]/*[1], $lang, 'fs')
                                    let $addressee := html:print-persname($i/ancestor::tei:correspDesc/tei:addressee[1]/*[1], $lang, 'fs')
                                    return (
                                        $sender, ' ', lang:get-language-string('writesTo', $lang), ' ', $addressee,
                                        if(ends-with($addressee, '.')) then ' ' else '. ',
                                        html-link:create-a-for-doc(
                                            $i/root(), 
                                            concat('[', lang:get-language-string('readOnLetter', $lang), ']'), 
                                            $lang, ('class=readOn')
                                        )
                                    )
                                )
                                else (
                                    html-link:create-a-for-doc($i/root(), core:printFornameSurname(query:getRegName($i/root()/*/@xml:id)), $lang, ()), ' ',
                                    lang:get-language-string($typeOfEvent, $lang)
                                )
                            }
                    }
                    </ul>
                </div>
            return doc(core:store-file($config:tmp-collection-path, $todaysEventsFileName, $output))/xhtml:div
(:            $output:)
};

(:~
 : Construct a name from a persName or name element wrapped in a <a> with @onmouseover etc.
 : If a @key is given on persName the regularized form will be returned, otherwise the content of persName.
 : If persName is empty than "unknown" is returned.
 : 
 : @author Peter Stadler
 : @param $persName the tei:persName element
 : @param $lang the current language (de|en)
 : @param $order (sf|fs) whether to print "surname, forename" or "forename surname"
 : @return 
 :)
declare function html:print-persname($persName as element(), $lang as xs:string, $order as xs:string) as element() {
    if(exists($persName/@key)) then html-link:create-a-for-doc(
        core:doc($persName/@key),
        if($order eq 'fs') then core:printFornameSurname(query:getRegName($persName/@key))
        else query:getRegName($persName/@key),
        $lang,
        ()
        )
    else if (exists($persName//text())) then <span class="noDataFound">{normalize-space($persName)}</span>
    else <span class="noDataFound">{lang:get-language-string('unknown',$lang)}</span>
};


(:~
 : Return the transcription text
 :
 : @author Peter Stadler
 : @param $docID ID of letter
 : @param $lang the current language (de|en)
 : @return 
 :)
(:
declare function html:print-doc-text($node as node(), $model as map(*), $docID as xs:string, $lang as xs:string) as element(xhtml:div) {
    let $doc := core:doc($docID)
    let $xslParams := 
        <parameters>
            <param name="lang" value="{$lang}"/>
            <param name="dbPath" value="{document-uri($doc)}"/>
            <param name="docID" value="{$docID}"/>
            <param name="transcript" value="true"/>
        </parameters>
    let $xslt := 
        if(config:is-letter($docID)) then doc($config:xsl-collection-path || "/letter_text.xsl")
        else if(config:is-news($docID)) then doc($config:xsl-collection-path || "/news.xsl")
        else if(config:is-writing($docID)) then doc($config:xsl-collection-path || "/doc_text.xsl")
        else ()
    let $head := 
        if(config:is-letter($docID)) then (\:wega:getLetterHead($doc, $lang):\) () (\: TODO :\)
        else if(config:is-news($docID)) then element h1 {string($doc//tei:title[@level='a'])}
        else if(config:is-writing($docID)) then (\:wega:getWritingHead($doc, $xslParams, $lang):\) () (\: TODO :\)
        else ()
    let $body := 
         if(functx:all-whitespace($doc//tei:text))
         (\: Entfernen von Namespace-Deklarationen: siehe http://wiki.apache.org/cocoon/RemoveNamespaces :\)
         then (
            let $summary := if(functx:all-whitespace($doc//tei:note[@type='summary'])) then () else core:change-namespace(transform:transform($doc//tei:note[@type='summary'], $xslt, $xslParams), '', ()) 
            let $incipit := if(functx:all-whitespace($doc//tei:incipit)) then () else core:change-namespace(transform:transform($doc//tei:incipit, $xslt, $xslParams), '', ())
            let $text := 
                if($doc//tei:correspDesc[@n = 'revealed']) then lang:get-language-string('correspondenceTextNotAvailable', $lang)
                else lang:get-language-string('correspondenceTextNotYetAvailable', $lang)
            return element div {
                attribute id {'teiLetter_body'},
                $incipit,
                $summary,
                element span {
                    attribute class {'notAvailable'},
                    $text
                }
            }
         )
         else (core:change-namespace(transform:transform($doc//tei:text, $xslt, $xslParams), '', ()))
     let $foot := 
        if(config:is-news($docID)) then (\:ajax:getNewsFoot($doc, $lang):\) () (\: TODO :\)
        else ()
     
     return (
        element xhtml:div {
            $head, $body, $foot
        }
    )
};
:)
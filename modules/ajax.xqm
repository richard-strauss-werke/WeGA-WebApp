xquery version "3.0" encoding "UTF-8";

 (:~
 : WeGA AJAX XQuery-Module
 :
 : @author Peter Stadler 
 : @version 1.0
 :)

module namespace ajax="http://xquery.weber-gesamtausgabe.de/modules/ajax";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
(:declare namespace xsd="http://www.w3.org/2001/XMLSchema";:)
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace session = "http://exist-db.org/xquery/session";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";
(:declare namespace cache = "http://exist-db.org/xquery/cache";:)
declare namespace util="http://exist-db.org/xquery/util";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace httpclient = "http://exist-db.org/xquery/httpclient";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace functx="http://www.functx.com";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets" at "facets.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace img="http://xquery.weber-gesamtausgabe.de/modules/img" at "img.xqm";
import module namespace norm="http://xquery.weber-gesamtausgabe.de/modules/norm" at "norm.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";
import module namespace datetime="http://exist-db.org/xquery/datetime" at "java:org.exist.xquery.modules.datetime.DateTimeModule";


(: Temporarily suppressing internal links to persons, works etc. since those are not reliable :)
declare variable $ajax:diaryYearsToSuppress as xs:integer* := 
    if($config:isDevelopment) then () 
    else (1810 to 1816, 1821 to 1826);

(:~
 : Creates HTML list for todays events
 : (function for index.xql)
 :
 : @author Peter Stadler
 : @author Christian Epp
 : @param $date todays date
 : @param $lang the current language (de|en)
 : @return element
 :)

declare function ajax:getTodaysEvents($date as xs:date, $lang as xs:string) as element(ul) {
    <ul>{
        for $teiDate in wega:getTodaysEvents($date)
        let $isJubilee := (year-from-date($date) - $teiDate/year-from-date(@when)) mod 25 = 0
        let $typeOfEvent := 
            if($teiDate/ancestor::tei:correspDesc) then 'letter'
            else if($teiDate[@type='baptism']) then 'isBaptised'
            else if($teiDate/parent::tei:birth) then 'isBorn'
            else if($teiDate[@type='funeral']) then 'wasBuried'
            else if($teiDate/parent::tei:death) then 'dies'
            else ()
        order by $teiDate/xs:date(@when) ascending
        return
            element li {
                if($isJubilee) then (
                    attribute class {'jubilee'},
                    attribute title {lang:get-language-string('roundYearsAgo',xs:string(year-from-date($date) - $teiDate/year-from-date(@when)), $lang)}
                )
                else (),
                concat(date:formatYear($teiDate/year-from-date(@when) cast as xs:int, $lang), ': '),
                if($typeOfEvent eq 'letter') then ajax:createLetterLink($teiDate, $lang)
                else (wega:createPersonLink($teiDate/root()/*/string(@xml:id), $lang, 'fs'), ' ', lang:get-language-string($typeOfEvent, $lang))
            }
    }</ul>
};

(:~
 : Helper function for ajax:createHtmlList
 :
 : @author Peter Stadler
 :)
declare %private function ajax:createLetterLink($teiDate as element(tei:date)?, $lang as xs:string) as item()* {
    let $sender := wega:printCorrespondentName($teiDate/ancestor::tei:correspDesc/tei:sender[1]/*[1], $lang, 'fs')
    let $addressee := wega:printCorrespondentName($teiDate/ancestor::tei:correspDesc/tei:addressee[1]/*[1], $lang, 'fs')
    return (
        $sender, ' ', lang:get-language-string('writesTo', $lang), ' ', $addressee, 
        if(ends-with($addressee, '.')) then ' ' else '. ', 
        wega:createDocLink($teiDate/root(), concat('[', lang:get-language-string('readOnLetter', $lang), ']'), $lang, ('class=readOn'))
    )
};


(:~
 : Returns a list of the todays events
 : (function for index.xql)
 :
 : @author Peter Stadler
 : @param $date todays date
 : @param $lang the current language (de|en)
 : @return element
 :)

(:declare function ajax:getTodaysEvents($date as xs:date?,$lang as xs:string) as document-node() {
    let $date := if(exists($date)) then $date else util:system-date()
    let $tmpDir := config:get-option('tmpDir')
    let $todaysEventsFileName := concat('todaysEventsFile_', $lang, '.xml')
    let $todaysEventsFile := doc(concat($tmpDir, $todaysEventsFileName))
    return
        if(xs:date($date) eq $todaysEventsFile/ul/xs:date(@class) and xmldb:last-modified($tmpDir, $todaysEventsFileName) gt config:getDateTimeOfLastDBUpdate() and false()) then $todaysEventsFile
        else doc(xmldb:store($tmpDir, concat('todaysEventsFile_', $lang, '.xml'), ajax:createHtmlList($date, $lang)))
};
:)
(:~
 : Returns correspondents by a person
 : (functions for person_singleView.xql)
 :
 : @author Peter Stadler 
 : @param $id of person
 : @param $lang the current language (de|en)
 : @param $fromOffset1
 : @param $toOffset1
 : @param $correspondents
 : @return element
 :)

declare function ajax:getPersonCorrespondents($id as xs:string, $lang as xs:string, $fromOffset1 as xs:string, $toOffset1 as xs:string, $correspondents as xs:string) as element()* {
    let $fromOffset := if($fromOffset1 castable as xs:date) then string($fromOffset1) else string('0001-01-01')
    let $toOffset   := if($toOffset1   castable as xs:date) then string($toOffset1)   else string('9999-01-01')
    let $letterList := if ($correspondents eq 'addressee')
        then core:getOrCreateColl('letters', $id, true())//tei:sender/tei:persName[@key = $id]
            [../../tei:dateSender/tei:date[@when >= $fromOffset and @when <= $toOffset] or 
            ../../tei:dateSender/tei:date[@notBefore >= $fromOffset and @notBefore <= $toOffset] or 
            ../../tei:dateSender/tei:date[@notAfter >= $fromOffset and @notAfter <= $toOffset] or 
            ../../tei:dateSender/tei:date[@to >= $fromOffset and @to <= $toOffset] or 
            ../../tei:dateSender/tei:date[@from >= $fromOffset and @from <= $toOffset] or
            ../../tei:dateSender/tei:date[not(@when or @from or @to or @notBefore or @notAfter)]]
            /../../tei:addressee/tei:persName[@key]
        else if ($correspondents eq 'sender')
            then core:getOrCreateColl('letters', $id, true())//tei:addressee/tei:persName[@key = $id]
            [../../tei:dateSender/tei:date[@when >= $fromOffset and @when <= $toOffset] or 
            ../../tei:dateSender/tei:date[@notBefore >= $fromOffset and @notBefore <= $toOffset] or 
            ../../tei:dateSender/tei:date[@notAfter >= $fromOffset and @notAfter <= $toOffset] or 
            ../../tei:dateSender/tei:date[@to >= $fromOffset and @to <= $toOffset] or 
            ../../tei:dateSender/tei:date[@from >= $fromOffset and @from <= $toOffset] or
            ../../tei:dateSender/tei:date[not(@when or @from or @to or @notBefore or @notAfter)]]
            /../../tei:sender/tei:persName[@key]
        else if ($correspondents eq 'all')
            then core:getOrCreateColl('letters', $id, true())//tei:persName[ancestor::tei:correspDesc][@key != $id]
        else()
    return 
        for $i in $letterList 
        group by $key := $i/@key
        order by count($i) descending
        return <person key="{$key}" count="{count($i)}"/>
};

(:~
 : Returns a DIV containing the correspondents to a person
 : (functions for person_singleView.xql)
 :
 : @author Peter Stadler
 : @param $id of person
 : @param $lang the current language (de|en)
 : @param $fromOffset1
 : @param $toOffset1
 : @param $correspondents
 : @param $max
 : @return element
 :)

declare function ajax:printCorrespondents($id as xs:string, $lang as xs:string, $fromOffset1 as xs:string, $toOffset1 as xs:string, $correspondents as xs:string, $max as xs:int) as element() {
    let $correspondents := ajax:getPersonCorrespondents($id, $lang, $fromOffset1, $toOffset1, $correspondents)
    let $baseHref := config:get-option('baseHref')
    let $linkElements := 
        for $x in subsequence($correspondents,1,$max)
        let $key := $x/string(@key)
        let $doc := core:doc($key)
        let $persNameSelected := wega:getRegName($key) (:wega:cleanString($person/tei:persName[@type='reg']):)
        let $persNameSelectedCount := $x/@count cast as xs:int
        order by $persNameSelectedCount descending, $persNameSelected ascending
        return
            if(exists($doc)) then
                element a {
                    attribute href {wega:createLinkToDoc($doc, $lang)},
                    attribute title {
                        if ($persNameSelectedCount gt 1) then concat($persNameSelected, ' (', $persNameSelectedCount, ' ', lang:get-language-string('letters',$lang), ')')
                        else concat($persNameSelected, ' (', $persNameSelectedCount, ' ', lang:get-language-string('letter',$lang), ')')},
                    element img {
                        attribute src {img:getPortraitPath($doc/tei:person, (40, 55), $lang)},
                        attribute alt {$persNameSelected},
                        attribute width {'40'},
                        attribute height {'55'}
                    }
                }
            else ()
    return element div{$linkElements}
};

(:~
 : Returns iconography list
 : (function for person_singleView.xql)
 :
 : @author Peter Stadler
 : @param $fffiID
 : @param $pnd
 : @param $lang the current language (de|en)
 : @return 
 :)

declare function ajax:getIconography($docID as xs:string, $pnd as xs:string, $lang as xs:string) as element(img)* {
    let $localIconography := core:getOrCreateColl('iconography', $docID, true())
    let $local-path := substring-after(config:getCollectionPath($docID), $config:data-collection-path || '/')
return
    (
    for $pic in $localIconography[.//tei:graphic/@url]
        let $caption := $pic//tei:titleStmt/tei:title
        let $graphicUrl := $pic//tei:graphic/string(@url)
        let $crop := if($pic//tei:graphic/xs:int(substring-before(@width, 'px')) > 400 or $pic//tei:graphic/xs:int(substring-before(@height, 'px')) > 600)
            then true()
            else false()
        let $localURL := core:join-path-elements(($local-path, $docID, $graphicUrl))
        let $thumbnail := <img src="{img:createDigilibURL($localURL, (40, 55), true())}" alt="{$caption}" width="40" height="55"/>
        return wega:createLightboxAnchor(img:createDigilibURL($localURL, $crop), $caption, 'person-iconography', $thumbnail),
        
    for $pic in img:retrieveImagesFromWikipedia($pnd,$lang)//wega:wikipediaImage
        return  <img src="{img:createDigilibURL($pic/wega:localUrl, (40, 55), true())}" alt="{$pic/wega:caption}" title="{$pic/wega:caption}" width="40" height="55"/>
    )
};

(:~
 : Returns the biography of a person
 : (function for person_singleView.xql)
 :
 : @author Peter Stadler
 : @param $id of the person
 : @param $lang the current language (de|en)
 : @return element
 :)

declare function ajax:getBiography($id as xs:string, $lang as xs:string) as element()* {
let $person := core:doc($id)
let $xslParams := config:get-xsl-params(())
let $baseHref := config:get-option('baseHref')
return (
    if($person//tei:note[@type="bioSummary"])
        then
            <div id="bioSummary">
                <h2>{lang:get-language-string('bioSummary',$lang)}</h2>
                {wega:changeNamespace(transform:transform($person//tei:note[@type="bioSummary"], doc(concat($config:xsl-collection-path, '/person_singleView.xsl')), $xslParams), '', ())}
            </div>
        else 
            if($person//tei:event) then ()
            else <div id="bioSummary"><i>({lang:get-language-string('noBioFound',$lang)})</i></div>,
        if($id eq 'A002068') then 
            if ($lang eq 'en') then ()
            else <p class="linkAppendix">Einen ausführlichen Lebenslauf finden Sie in der <a href="{core:join-path-elements(($baseHref, '/de/Biographie'))}">erweiterten Biographie</a></p> 
        else wega:getEvents($person/tei:person,$lang)
        )
};

(:~
 : Grab Wikipedia article for a given PND
 : (functions for person_singleView.xql)
 :
 : @author Peter Stadler
 : @param $pnd the PND number
 : @param $lang the language variable (de|en)
 : @return div for insertion into a xhtml page 
 :)
 
declare function ajax:getWikipedia($pnd as xs:string, $lang as xs:string) as element() {
    let $pnd := request:get-parameter('pnd','118629662')
    let $lang := request:get-parameter('lang', 'de')
    let $wikiContent := wega:grabExternalResource('wikipedia', $pnd, $lang, true())
    let $wikiUrl := $wikiContent//xhtml:div[@class eq 'printfooter']/xhtml:a[1]/data(@href)
    let $xslParams := config:get-xsl-params(())
    let $name := normalize-space($wikiContent//xhtml:h1[@id = 'firstHeading'])
    let $appendix := if($lang eq 'en') then 
        <p class="linkAppendix">The content of this "Wikipedia" entitled box is taken from the article "<a href='{$wikiUrl}' title='Wikipedia article for {$name}'>{$name}</a>" 
        from <a href="http://en.wikipedia.org">Wikipedia</a>, the free encyclopedia, 
        and is released under a <a href="http://creativecommons.org/licenses/by-sa/3.0/deed.en">CC-BY-SA-license</a>.
        You will find the <a href="{concat(replace($wikiUrl, 'wiki/', 'w/index.php?title='), '&amp;action=history')}" title="Authors and revision history of the Wikipedia Article for {$name}">revision history along with the authors</a> of this article in Wikipedia.</p>
        
        else 
        <p class="linkAppendix">Der Inhalt dieser mit "Wikipedia" bezeichneten Box entstammt dem Artikel "<a href='{$wikiUrl}' title='Wikipedia Artikel zu "{$name}"'>{$name}</a>" 
        aus der freien Enzyklopädie <a href="http://de.wikipedia.org" title="Wikipedia Hauptseite">Wikipedia</a> 
        und steht unter der <a href="http://creativecommons.org/licenses/by-sa/3.0/deed.de">CC-BY-SA-Lizenz</a>. 
        In der Wikipedia findet sich auch die <a href="{concat(replace($wikiUrl, 'wiki/', 'w/index.php?title='), '&amp;action=history')}" title='Autoren und Versionsgeschichte des Wikipedia Artikels zu "{$name}"'>Versionsgeschichte mitsamt Autorennamen</a> für diesen Artikel.</p>

    let $result := if(exists($wikiContent//xhtml:meta)) 
        then (
            <div class="wikipediaText">
                {transform:transform($wikiContent//xhtml:div[@id='bodyContent'], doc(concat($config:xsl-collection-path, '/person_wikipedia.xsl')), $xslParams)}
                {$appendix}
            </div>
        )
        else <span class="notAvailable">{lang:get-language-string('noWikipediaEntryFound', $lang)}</span>
        
    return 
    (:wega:castDateFormat('Wed, 03 Apr 2010 19:09:48 GMT'):)
        wega:changeNamespace($result, '', ())
};

(:~
 : Grab ADB article from wikisource for a given PND
 : (function for person_singleView.xql)
 :
 : @author Peter Stadler
 : @param $pnd the PND number
 : @param $lang the language variable (de|en)
 : @return div for insertion into a xhtml page 
 :)
 
declare function ajax:getADB($pnd as xs:string, $lang as xs:string) as element() {
    let $pnd := request:get-parameter('pnd','118629662')
    let $lang := request:get-parameter('lang', 'de')
    let $wikiContent := wega:grabExternalResource('adb', $pnd, (), true())
    let $xslParams := config:get-xsl-params(())
    let $name := normalize-space($wikiContent//xhtml:h1[@id = 'firstHeading'])
    let $appendix := transform:transform($wikiContent//xhtml:div[@id='adbcite'], doc(concat($config:xsl-collection-path, '/person_wikipedia.xsl')), <parameters><param name="lang" value="{$lang}"/><param name="mode" value="appendix"/></parameters>)
    let $result := if(exists($wikiContent//xhtml:meta)) 
        then (
            <div class="wikipediaText">
                {transform:transform($wikiContent//xhtml:div[@id='bodyContent'], doc(concat($config:xsl-collection-path, '/person_wikipedia.xsl')), $xslParams)}
                {$appendix}
            </div>
        )
        else <span class="notAvailable">{lang:get-language-string('noADBEntryFound', $lang)}</span>
        
    return 
    (:wega:castDateFormat('Wed, 03 Apr 2010 19:09:48 GMT'):)
        wega:changeNamespace($result, '', ())
};

(:~
 : Grab DNB site for information for a given PND
 : (function for person_singleView.xql)
 :
 : @author Peter Stadler
 : @param $pnd the PND number
 : @param $lang the language variable (de|en)
 : @return div for insertion into a xhtml page 
 :)
 
declare function ajax:getDNB($pnd as xs:string, $lang as xs:string) as element(div) {
    let $dnbContentRoot := wega:grabExternalResource('dnb', $pnd, (), true())//httpclient:body//xhtml:div[@class='chapters'][data(./xhtml:h2)=concat(config:get-option('dnb'),$pnd)]/xhtml:table[1]
    let $name := normalize-space($dnbContentRoot//xhtml:td[preceding-sibling::xhtml:td/xhtml:strong = 'Person'])
    let $roleName := normalize-space($dnbContentRoot//xhtml:td[preceding-sibling::xhtml:td/xhtml:strong = 'Adelstitel'])
    let $otherNames := string-join($dnbContentRoot//xhtml:td[preceding-sibling::xhtml:td/xhtml:strong ='Andere Namen']/text()/normalize-space(.), '; ') 
    let $dates := for $i in $dnbContentRoot//xhtml:td/text()[matches(., 'Lebensdaten')] return normalize-space(substring-after($i, 'Lebensdaten: '))
    let $occupation := string-join($dnbContentRoot//xhtml:td[preceding-sibling::xhtml:td/xhtml:strong ='Beruf(e)']/xhtml:a, ', ')
    let $appendix := if($lang='en') then <p class="linkAppendix">For associated publications and further information please visit <a href="http://d-nb.info/gnd/{$pnd}" title="DNB-entry for {$name}">the complete entry</a> at the German National Library.</p>
            else <p class="linkAppendix">Zu verknüpfter Literatur und weiteren Informationen siehe den <a href="http://d-nb.info/gnd/{$pnd}" title="DNB-Eintrag für {$name}">vollständigen Eintrag</a> in der Deutschen Nationalbibliothek.</p>
    return (
        <div id="dnbFrame">
            <ul>
                <li><span class="desc">{lang:get-language-string('pnd_name', $lang)}:</span> {$name}</li>
                {
                if ($roleName ne '') then element li {element span {attribute class {"desc"}, concat(lang:get-language-string('pnd_roleName', $lang), ':')}, $roleName} else(),
                if (exists($dates)) then for $date in $dates return element li {element span {attribute class {"desc"}, concat(lang:get-language-string('pnd_dates', $lang), ':')}, $date} else(),
                if ($occupation ne '') then element li {element span {attribute class {"desc"}, concat(lang:get-language-string('pnd_occupation', $lang), ':')}, $occupation} else(),
                if ($otherNames ne '') then element li {element span {attribute class {"desc"}, concat(lang:get-language-string('pnd_otherNames', $lang), ':')}, $otherNames} else()
                }
            </ul>
            {$appendix}
        </div>
        )
};

(:~
 : Query beacon.findbuch.de for a list of institutions that hold information for a given pnd
 : (functions for person_singleView.xql)
 :
 : @author Peter Stadler
 : @param $pnd the PND number
 : @param $lang the language variable (de|en)
 : @return element
 :)
 
declare function ajax:getPNDBeacons($pnd as xs:string, $name as xs:string, $lang as xs:string) as element(div) {
    let $findbuchResponse := wega:grabExternalResource('beacon', $pnd, (), true())
        (:util:binary-to-string(wega:grabExternalResource('beacon', $pnd, (), true())):)
    let $jxml := 
        if(exists($findbuchResponse)) then 
            if($findbuchResponse/httpclient:body/@encoding = 'Base64Encoded') then xqjson:parse-json(util:binary-to-string($findbuchResponse))
            else xqjson:parse-json($findbuchResponse)
        else ()
    let $list :=
          <ul>{
            for $i in 1 to count($jxml/item[2]/item)
            let $link  := normalize-space($jxml/item[4]/item[$i])
            let $title := normalize-space($jxml/item[3]/item[$i])
            let $text  := normalize-space($jxml/item[2]/item[$i])
            return
                if(matches($link,"weber-gesamtausgabe.de")) then ()
                else <li><a title="{$title}" href="{$link}">{$text}</a></li>
          }
          </ul>
    return 
        <div>{
            if (exists($list/li)) then (
                <h2>{lang:get-language-string('beaconLinks', ($name,$pnd), $lang)}</h2>,
                $list
            )
            else <span class="notAvailable">{lang:get-language-string('noBeaconsFound', $lang)}</span>
        }</div>
};

(:~
 : Gets list from entries with key
 : (functions for letter_singleView.xql)
 :
 : @author Peter Stadler
 : @param $docID
 : @param $lang the language variable (de|en)
 : @param $entry
 : @return element
 :)
 
declare function ajax:getListFromEntriesWithKey($docID,$lang,$entry) {
    let $doc := core:doc($docID)
    let $isDiary := config:is-diary($docID)
    (: Temporarily suppressing display of persons, works etc. since those are not reliable :)
    let $suppressDisplay := if($isDiary) then if(year-from-date($doc/tei:ab/@n cast as xs:date) = $ajax:diaryYearsToSuppress) then true() else false() else false()
    let $tokenizeIDs := function($key as xs:string) as xs:string* {
        tokenize($key, '\s+')
    }
    let $coll := 
        if ($entry eq 'person') then
            if($isDiary) then map($tokenizeIDs, ($doc//tei:persName[not(ancestor::tei:note)]/string(@key), $doc//tei:rs[@type = ('person', 'persons')][not(ancestor::tei:note)]/string(@key)))
            else map($tokenizeIDs, ($doc//tei:text//tei:persName[not(ancestor::tei:note)]/string(@key), $doc//tei:text//tei:rs[@type = ('person', 'persons')][not(ancestor::tei:note)]/string(@key)))
        else if ($entry eq 'work') then 
            if($isDiary) then map($tokenizeIDs, ($doc//tei:workName[not(ancestor::tei:note)]/@key, $doc//tei:rs[@type = ('work', 'works')][not(ancestor::tei:note)]/@key))
            else map($tokenizeIDs, ($doc//tei:text//tei:workName[not(ancestor::tei:note)]/@key, $doc//tei:text//tei:rs[@type = ('work', 'works')][not(ancestor::tei:note)]/@key))
        else ()
    return if (count($coll) ne 0 and not($suppressDisplay)) then (
        for $x in distinct-values($coll)
        let $regName := 
            if($entry eq 'person') then wega:getRegName($x)
            else if($entry eq 'work') then wega:getRegTitle($x)
            else ()
        order by $regName ascending
        return 
        <li onclick="highlightSpanClassInText('{$x}',this)">{$regName}</li>
    )
    else (<li class="noDataFound">{lang:get-language-string('noDataFound',$lang)}</li>)
};

(:~
 : Returns letter context
 : (functions for requestLetterContext)
 :
 : @author Peter Stadler
 : @param $docID ID of letter
 : @param $lang the current language (de|en)
 : @return element 
 :)

declare function ajax:requestLetterContext($docID as xs:string, $lang as xs:string) as element()* {
    let $doc := core:doc($docID)
    let $authorID := $doc//tei:fileDesc/tei:titleStmt/tei:author[1]/@key (:$doc//tei:sender/tei:persName[1]/@key:)
    let $addresseeID := $doc//tei:addressee/tei:persName[1]/@key
    let $normDates := if(exists($authorID)) then norm:get-norm-doc('letters') else ()
    
    (: Vorausgehender Brief in der Liste des Autors (= vorheriger von-Brief) :)
    let $prevLetterFromSender := $normDates//norm:entry[@docID = $docID][not(functx:all-whitespace(.))]/preceding-sibling::norm:entry[@authorID = $authorID][not(functx:all-whitespace(.))][position() eq last()]
    (: Vorausgehender Brief in der Liste an den Autors (= vorheriger an-Brief) :)
    let $prevLetterToSender := $normDates//norm:entry[@docID = $docID][not(functx:all-whitespace(.))]/preceding-sibling::norm:entry[@addresseeID = $authorID][not(functx:all-whitespace(.))][position() eq last()]
    (: Nächster Brief in der Liste des Autors (= nächster von-Brief) :)
    let $nextLetterFromSender := $normDates//norm:entry[@docID = $docID][not(functx:all-whitespace(.))]/following-sibling::norm:entry[@authorID = $authorID][not(functx:all-whitespace(.))][xs:integer(1)] 
    (: Nächster Brief in der Liste an den Autor (= nächster an-Brief) :)
    let $nextLetterToSender := $normDates//norm:entry[@docID = $docID][not(functx:all-whitespace(.))]/following-sibling::norm:entry[@addresseeID = $authorID][not(functx:all-whitespace(.))][xs:integer(1)]
    (: Direkter vorausgehender Brief des Korrespondenzpartners (worauf dieser eine Antwort ist) :)
    let $prevLetterFromAddressee := $normDates//norm:entry[@docID = $docID][not(functx:all-whitespace(.))]/preceding-sibling::norm:entry[@authorID = $addresseeID][@addresseeID = $authorID][not(functx:all-whitespace(.))][position() eq last()]
    (: Direkter vorausgehender Brief des Autors an den Korrespondenzpartner :)
    let $prevLetterFromAuthorToAddressee := $normDates//norm:entry[@docID = $docID][not(functx:all-whitespace(.))]/preceding-sibling::norm:entry[@authorID = $authorID][@addresseeID = $addresseeID][not(functx:all-whitespace(.))][position() eq last()]
    (: Direkter Antwortbrief des Adressaten:)
    let $replyLetterFromAddressee := $normDates//norm:entry[@docID = $docID][not(functx:all-whitespace(.))]/following-sibling::norm:entry[@authorID = $addresseeID][@addresseeID = $authorID][not(functx:all-whitespace(.))][xs:integer(1)]
    (: Antwort des Autors auf die Antwort des Adressaten :)
    let $replyLetterFromSender := $normDates//norm:entry[@docID = $docID][not(functx:all-whitespace(.))]/following-sibling::norm:entry[@authorID = $authorID][@addresseeID = $addresseeID][not(functx:all-whitespace(.))][xs:integer(1)] 
    return (
        <h3>{lang:get-language-string('absouluteChronology',$lang)}</h3>,
        <h4>{lang:get-language-string('prevLetters',$lang)}</h4>,
        <ul>{
          ajax:printLetterContextLink($prevLetterFromSender, false(), $lang),
          ajax:printLetterContextLink($prevLetterToSender, true(), $lang),
        (: Ausgabe von "no data found" when keiner der o.a. Briefe existiert, z.B. bei undatierten Briefen :)    
          if(exists($prevLetterFromSender) or exists($prevLetterToSender))
              then ()
              else <li class="noDataFound">{lang:get-language-string('noDataFound',$lang)}</li>
        }</ul>,
        <h4>{lang:get-language-string('nextLetters',$lang)}</h4>,
        <ul>{
          ajax:printLetterContextLink($nextLetterFromSender, false(), $lang),
          ajax:printLetterContextLink($nextLetterToSender, true(), $lang),
        (: Ausgabe von "no data found" when keiner der o.a. Briefe existiert, z.B. bei undatierten Briefen :)
          if(exists($nextLetterFromSender) or exists($nextLetterToSender))
              then()
              else <li class="noDataFound">{lang:get-language-string('noDataFound',$lang)}</li>
        }</ul>,
        <h3>{lang:get-language-string('korrespondenzstelle',$lang)}</h3>,
        <h4>{lang:get-language-string('prevLetters',$lang)}</h4>,
        <ul>{
            ajax:printLetterContextLink($prevLetterFromAuthorToAddressee, false(), $lang),
            ajax:printLetterContextLink($prevLetterFromAddressee, true(), $lang),
            (: Ausgabe von "no data found" when keiner der o.a. Briefe existiert, z.B. bei undatierten Briefen :)
            if(exists($prevLetterFromAuthorToAddressee) or exists($prevLetterFromAddressee))
                then()
                else <li class="noDataFound">{lang:get-language-string('noDataFound',$lang)}</li>
        }</ul>,
        <h4>{lang:get-language-string('nextLetters',$lang)}</h4>,
        <ul>{
            ajax:printLetterContextLink($replyLetterFromSender, false(), $lang),
            ajax:printLetterContextLink($replyLetterFromAddressee, true(), $lang),
            (: Ausgabe von "no data found" when keiner der o.a. Briefe existiert, z.B. bei undatierten Briefen :)
            if(exists($replyLetterFromSender) or exists($replyLetterFromAddressee))
                then()
                else <li class="noDataFound">{lang:get-language-string('noDataFound',$lang)}</li>
        }</ul>
    )
};

(:~
 : Returns context of letter
 : (functions for requestLetterContext)
 :
 : @author Peter Stadler
 : @param $docNormEntry
 : @param $from 
 : @param $lang the current language (de|en)
 : @return element
 :)

declare function ajax:printLetterContextLink($docNormEntry as element(norm:entry)?, $from as xs:boolean, $lang as xs:string) as element(li)? {
    if(exists($docNormEntry)) then (
        let $docID := $docNormEntry/data(@docID)
        let $doc := core:doc($docID)
        let $authorID := if($docNormEntry/@authorID ne '') then $docNormEntry/data(@authorID) else config:get-option('anonymusID')
        let $linkText := if($docNormEntry eq '') then lang:get-language-string('withoutDate', $lang) else string($docNormEntry)
        let $additionalText := if($from) 
            then (concat(lang:get-language-string('from', $lang), ' '), wega:printCorrespondentName($doc//tei:fileDesc/tei:titleStmt/tei:author[1], $lang, 'fs')) 
            else (concat(lang:get-language-string('to',   $lang), ' '), wega:printCorrespondentName($doc//tei:addressee[1]/*[1], $lang, 'fs')) (: siehe Ticket #739 :)
        return 
        element li {
            wega:createDocLink($doc, $linkText, $lang, ()),
            ': ',
            $additionalText
        }
    )
    else ()
};

(:~
 : Gets list from entries without keys
 : (functions for requestLetterContext)
 :
 : @author Peter Stadler
 : @param $docID ID of letter
 : @param $lang the current language (de|en)
 : @param $entry
 : @return 
 :)

declare function ajax:getListFromEntriesWithoutKey($docID,$lang,$entry) {
    let $doc := core:doc($docID)
    let $coll := if($entry = 'person')
     then $doc//tei:text//tei:persName[not(@key)] | $doc//tei:text//tei:rs[@type='person' or @type='persons'][not(@key)] | (: Letters :)
         $doc//tei:ab//tei:persName[not(@key)] | $doc//tei:ab//tei:rs[@type='person' or @type='persons'][not(@key)] (: Diaries :)
     else if($entry = 'work')
         then $doc//tei:text//tei:workName | $doc//tei:text//tei:rs[@type='work' or @type='works'] |
             $doc//tei:ab//tei:workName | $doc//tei:ab//tei:rs[@type='work' or @type='works']
         else if($entry = 'character')
             then $doc//tei:text//tei:characterName | 
                 $doc//tei:ab//tei:characterName
             else if($entry = 'place')
                 then $doc//tei:text//tei:placeName | 
                     $doc//tei:ab//tei:placeName
                 else ()    
    return if (exists($coll)) 
     then (
         for $entry in distinct-values($coll)
         let $asciiCode := string-join(for $i in (string-to-codepoints(normalize-space(data($entry)))) return string($i),'')
         order by $entry ascending
         return (<li onclick="highlightSpanClassInText('{$asciiCode}',this)">{data($entry)}</li>))
    
     else (<li class="noDataFound">{lang:get-language-string('noDataFound',$lang)}</li>)
};

(:~
 : Return the transcription text
 :
 : @author Peter Stadler
 : @param $docID ID of letter
 : @param $lang the current language (de|en)
 : @return 
 :)

declare function ajax:printTranscription($docID as xs:string, $lang as xs:string) as item()* {
    let $doc := core:doc($docID)
    let $xslParams := config:get-xsl-params( map {
        'dbPath' := document-uri($doc),
        'docID' := $docID,
        'transcript' := 'true'
        } )
    let $xslt := 
        if(config:is-letter($docID)) then doc(concat($config:xsl-collection-path, '/letter_text.xsl'))
        else if(config:is-news($docID)) then doc(concat($config:xsl-collection-path, '/news.xsl'))
        else if(config:is-writing($docID)) then doc(concat($config:xsl-collection-path, '/doc_text.xsl'))
        else ()
    let $head := 
        if(config:is-letter($docID)) then wega:getLetterHead($doc, $lang)
        else if(config:is-news($docID)) then element h1 {
            transform:transform($doc//tei:fileDesc/tei:titleStmt/tei:title[@level='a'], doc(concat($config:xsl-collection-path, '/common_main.xsl')), config:get-xsl-params(()))
            (:string($doc//tei:title[@level='a']):)
            }
        else if(config:is-writing($docID)) then wega:getWritingHead($doc, $xslParams, $lang)
        else ()
    let $body := 
         if(functx:all-whitespace($doc//tei:text))
         (: Entfernen von Namespace-Deklarationen: siehe http://wiki.apache.org/cocoon/RemoveNamespaces :)
         then (
            let $summary := if(functx:all-whitespace($doc//tei:note[@type='summary'])) then () else wega:changeNamespace(transform:transform($doc//tei:note[@type='summary'], doc(concat($config:xsl-collection-path, '/letter_text.xsl')), $xslParams), '', ()) 
            let $incipit := if(functx:all-whitespace($doc//tei:incipit)) then () else wega:changeNamespace(transform:transform($doc//tei:incipit, doc(concat($config:xsl-collection-path, '/letter_text.xsl')), $xslParams), '', ())
            let $text := if($doc//tei:correspDesc[@n = 'revealed']) then lang:get-language-string('correspondenceTextNotAvailable', $lang)
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
         else (wega:changeNamespace(transform:transform($doc//tei:text, $xslt, $xslParams), '', ()))
     let $foot := 
        if(config:is-news($docID)) then ajax:getNewsFoot($doc, $lang)
        else ()
     
     return ($head, $body, $foot)
};

(:~
 : Create dateline and author link for website news
 : (Helper Function for ajax:printTranscription())
 :
 : @author Peter Stadler
 : @param $doc the news document node
 : @param $lang the current language (de|en)
 : @return element html:p
 :)
 
declare function ajax:getNewsFoot($doc as document-node(), $lang as xs:string) as element(p)? {
    let $authorID := data($doc//tei:titleStmt/tei:author[1]/@key)
    let $dateFormat := 
        if ($lang = 'en') then '%A, %B %d, %Y'
                          else '%A, %d. %B %Y'
    return 
        if($authorID) then 
            element p {
                attribute class {'authorDate'},
                wega:createPersonLink($authorID, $lang, 'fs'), 
                concat(', ', date:strfdate(datetime:date-from-dateTime($doc//tei:publicationStmt/tei:date/@when), $lang, $dateFormat))
            }
        else()
};

(:~
 : Returns transcription of diary site
 : (functions for diary_singleView.xql)
 :
 : @author Peter Stadler
 : @param $docID ID of diary entry
 : @param $lang the current language (de|en)
 : @return element
 :)
 
declare function ajax:diary_printTranscription($docID as xs:string, $lang as xs:string) {
    let $doc := core:doc($docID)
    let $curYear := year-from-date($doc/tei:ab/@n cast as xs:date)
    let $xslParams := config:get-xsl-params(map:new((map:entry('transcript', 'true'), if($curYear = $ajax:diaryYearsToSuppress) then map:entry('suppressLinks', 'true') else ())))
    let $dateFormat := if ($lang eq 'en')
        then '%A, %B %d, %Y'
        else '%A, %d. %B %Y'
    return 
        <div class="diaryDay" id="{$doc/tei:ab/string(@xml:id)}">
            <h2>{date:strfdate(xs:date($doc/tei:ab/@n), $lang, $dateFormat)}</h2>
            {wega:changeNamespace(transform:transform($doc, doc(concat($config:xsl-collection-path, '/diary_tableLeft.xsl')), $xslParams), '', ())}
            {wega:changeNamespace(transform:transform($doc, doc(concat($config:xsl-collection-path, '/diary_tableRight.xsl')), $xslParams), '', ())}
        </div>,
        <div class="clearer"></div>
};

(:~
 : Returns context of diary site
 : (functions for diary_singleView.xql)
 :
 : @author Peter Stadler
 : @param $contextContainer
 : @param $docID ID of diary entry
 : @param $lang the current language (de|en)
 : @return element
 :)

declare function ajax:getDiaryContext($contextContainer as xs:string, $docID as xs:string, $lang as xs:string) as element(div) {
    let $authorID := 'A002068'
    let $normDates := norm:get-norm-doc('diaries')
    let $preceding := $normDates//norm:entry[@docID = $docID]/preceding-sibling::norm:entry[position() = last()]
    let $following := $normDates//norm:entry[@docID = $docID]/following-sibling::norm:entry[1]
    return 
    <div id="{$contextContainer}">
        <h2>{lang:get-language-string('context', $lang)}</h2>
        <ul>{
            if($preceding) then
                element li {
                    lang:get-language-string('prevDiaryDay', $lang),
                    <br/>,
                    wega:createDocLink(core:doc($preceding/@docID), date:getNiceDate($preceding/text() cast as xs:date, $lang), $lang, ())
                }
            else (),
            if($following) then
                element li {
                    lang:get-language-string('nextDiaryDay', $lang),
                    <br/>,
                    wega:createDocLink(core:doc($following/@docID), date:getNiceDate($following/text() cast as xs:date, $lang), $lang, ())
                }
            else ()
            }
        </ul>
    </div>
};

(:~
 : Returns context of news
 : (function for news_singleView.xql)
 :
 : @author Peter Stadler
 : @param $contextContainer
 : @param $docID news ID
 : @param $lang the current language (de|en)
 : @return 
 :)

declare function ajax:getNewsContext($contextContainer as xs:string, $docID as xs:string, $lang as xs:string) {
    let $normDates := norm:get-norm-doc('news') 
    let $following := $normDates//norm:entry[@docID = $docID]/preceding-sibling::norm:entry[position() = last()]
    let $preceding := $normDates//norm:entry[@docID = $docID]/following-sibling::norm:entry[1]
    let $baseHref := config:get-option('baseHref') 
    return 
    <div id="{$contextContainer}">
        <h2>{lang:get-language-string('context', $lang)}</h2>
        <ul>{
            if($preceding) (: Absteigende Sortierung! :)
                then element li {
                    lang:get-language-string('prevDiaryDay', $lang),
                    <br/>,
                    wega:createDocLink(core:doc($preceding/@docID), date:getNiceDate($preceding/text() cast as xs:date, $lang), $lang, ()) (: Absteigende Sortierung! :)
                }
                else (),
            if($following)  (: Absteigende Sortierung! :)
                then element li {
                    lang:get-language-string('nextDiaryDay', $lang),
                    <br/>,
                    wega:createDocLink(core:doc($following/@docID), date:getNiceDate($following/text() cast as xs:date, $lang), $lang, ()) (: Absteigende Sortierung! :)
                }
                else (),
            element li {
                attribute class {'gotoArchive'},
                element a {
                    attribute href {core:join-path-elements(($baseHref, $lang, lang:get-language-string('indices', $lang), lang:get-language-string('news', $lang)))},
                    attribute title {lang:get-language-string('newsArchive', $lang)},
                    lang:get-language-string('goToArchive', $lang)
                }
            }
            }
        </ul>
    </div>
};

(:~
 : True, if collection to the docType is in session
 :
 : @author Peter Stadler
 : @param $docType
 : @return xs:boolean
 :)

(:  Wird gerade erstmal nicht mehr genutzt?? :)
declare function ajax:isFilterColl($docType) {
    let $sessionCollName := facets:getCollName($docType, false())
    let $coll := session:get-attribute($sessionCollName)
    return exists($coll)
};
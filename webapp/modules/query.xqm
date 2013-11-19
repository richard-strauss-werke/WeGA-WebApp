xquery version "3.0";

(:~
 : Module for querying the data
 :)
module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace functx="http://www.functx.com" at "functx.xqm";

(:~
 : Get the latest news from the news collection
 :
 : @author Peter Stadler
 : @return the news documents
 :)
declare function query:get-latest-news($date as xs:date?) as document-node()* {
    let $maxNews := xs:integer(config:get-option('maxNews'))
    let $minNews := xs:integer(config:get-option('minNews'))
    let $maxNewsDays := xs:integer(config:get-option('maxNewsDays'))
    let $date := 
        if(exists($date)) then $date
        else current-date() 
    let $newsColl := subsequence(core:getOrCreateColl('news', 'indices', true())[days-from-duration($date - xs:date(.//tei:publicationStmt/tei:date/xs:dateTime(@when))) le $maxNewsDays], 1, $maxNews)
    
    return 
        if(count($newsColl) lt $minNews) then subsequence(core:getOrCreateColl('news', 'indices', true()), 1, $minNews)
        else $newsColl 
};

declare function query:get-todays-events($date as xs:date) as element(tei:date)*{
    let $day := functx:pad-integer-to-length(day-from-date($date), 2)
    let $month := functx:pad-integer-to-length(month-from-date($date), 2)
    let $date-regex := '^'||string-join(('\d{4}',$month,$day),'-')||'$'
    return 
        collection($config:data-collection-path || '/letters')//tei:dateSender/tei:date[matches(@when, $date-regex)] union
        collection($config:data-collection-path || '/persons')//tei:date[matches(@when, $date-regex)][parent::tei:birth or parent::tei:death]
        (:core:getOrCreateColl('letters', 'indices', true())//tei:dateSender/tei:date[@when castable as xs:date][day-from-date(@when) eq $day][month-from-date(@when) eq $month]:)
};

(:~
 : Grab the first author from a TEI document or the first composer of a MEI document respectively
 :
 : @author Peter Stadler 
 : @param $item the id of the document (or the document node itself) to grab the author from
 : @return xs:string the ID of the author
:)
declare function query:getAuthorIDOfDoc($item as item()) as xs:string? {
    let $doc := typeswitch($item)
        case xs:string return core:doc($item)
        case document-node() return $item
        default return ()
    let $docID := $doc/*/data(@xml:id)
    return 
        if(exists($doc)) then 
            if(config:is-diary($docID)) then 'A002068' (: Diverse Sonderbehandlungen fürs Tagebuch :)
            else if(exists($doc//mei:titleStmt/mei:respStmt/mei:persName[@role = 'cmp'][1]/@dbkey)) then $doc//mei:titleStmt/mei:respStmt/mei:persName[@role = 'cmp'][1]/string(@dbkey)
            else if(exists($doc/*/mei:ref)) then query:getAuthorIDOfDoc($doc/*/mei:ref/data(@target))
            else if(exists($doc//tei:fileDesc/tei:titleStmt/tei:author[1]/@key)) then $doc//tei:fileDesc/tei:titleStmt/tei:author[1]/string(@key)
            else if(exists($doc/*/tei:ref)) then query:getAuthorIDOfDoc($doc/*/tei:ref/data(@target))
            else config:get-option('anonymusID')
        else ()
};

(:~
 : Get the regularized name of a person
 :
 : @param $key the db-key of the person
 : @author Peter Stadler
 : @return xs:string
 :)
declare function query:getRegName($key as xs:string) as xs:string {
(:    Leider zu langsam:)
    normalize-space(collection($config:data-collection-path || '/persons')//id($key)/tei:persName[@type='reg'])
(:    let $response := wega:dictionaryLookup(concat('_', $key), 'persNamesFile'):)
    (:let $dictionary := wega:getNormDates('persons') 
    let $response := $dictionary//entry[@docID = $key]
    return 
        if(exists($response)) then $response/text() cast as xs:string
        else '':)
};

(:~
 : Gets reg title
 :
 : @author Peter Stadler
 : @param $docID
 : @return xs:string
 :)

declare function query:getRegTitle($docID as xs:string) as xs:string {
    let $doc := core:doc($docID)
    return
        if(config:is-diary($docID)) then ()
        else if(config:is-work($docID)) then normalize-space($doc//mei:fileDesc/mei:titleStmt/mei:title[@type = 'main'][1]) (: Index korrupt!! :) 
        else normalize-space($doc//tei:fileDesc/tei:titleStmt/tei:title[@level = 'a'][1])
};


(:~
 : Gets letter header
 :
 : @author Peter Stadler
 : @param $doc document node
 : @param $lang the current language (de|en)
 : @return element
 :)
declare function query:get-letterHead($doc as document-node(), $lang as xs:string) as xs:string+ {
    let $docTitle := $doc//tei:fileDesc/tei:titleStmt/tei:title[@level="a"]/text()
    return 
        if($docTitle) then (
            $docTitle[1],
            $docTitle[2]
        )
        else query:construct-letterHead($doc, $lang)
};


(:~
 : Constructs letter header
 : (helper function for query:get-letterHead())
 : @author Peter Stadler
 : @param $doc document node
 : @param $lang the current language (de|en)
 : @return element
:)
declare %private function query:construct-letterHead($doc as document-node(), $lang as xs:string) as xs:string+ {
    let $id := $doc/tei:TEI/string(@xml:id)
    let $date := if(exists(date:getOneNormalizedDate($doc//tei:dateSender/tei:date[1], false())))
        then date:strfdate(date:getOneNormalizedDate($doc//tei:dateSender/tei:date[1], false()), $lang, ())
        else lang:get-language-string('undated', $lang)
    let $sender := core:printFornameSurname($doc//tei:sender/*[1]) (: wega:printCorrespondentName($doc//tei:sender/*[1], $lang, 'fs'):)
    let $addressee := core:printFornameSurname($doc//tei:addressee/*[1]) (:wega:printCorrespondentName($doc//tei:addressee/*[1], $lang, 'fs'):)
    let $placeSender := if(normalize-space($doc//tei:placeSender) ne '') then normalize-space($doc//tei:placeSender) else ()
    let $placeAddressee := if(normalize-space($doc//tei:placeAddressee) ne '') then normalize-space($doc//tei:placeAddressee) else ()
    return (
        concat(
            $sender, ' ', 
            lower-case(lang:get-language-string('to', $lang)), ' ', 
            $addressee,
            if(exists($placeAddressee)) then concat(' ', lower-case(lang:get-language-string('in', $lang)), ' ', $placeAddressee) else()
        ),
        string-join(($placeSender, $date), ', ')
    )
};

declare function query:get-list-from-entries-with-key($node as node(), $model as map(*), $docID as xs:string, $lang as xs:string, $entry as xs:string) as map(*) {
    let $doc:= core:doc($docID)
    let $isDiary := config:is-diary($docID)
    (: Temporarily suppressing display of persons, works etc. since those are not reliable :)
    let $yearsToSuppress := if(config:get-option('environment') eq 'development') then  () else (1813,1814,1815,1816,1821,1822,1823,1826)
    let $suppressDisplay := if($isDiary) then if(year-from-date($doc/tei:ab/@n cast as xs:date) = $yearsToSuppress) then true() else false() else false()
    let $coll := 
        if ($entry eq 'persons') then
            if($isDiary) then functx:value-union($doc//tei:persName/string(@key), functx:value-union($doc//tei:rs[@type eq 'person']/string(@key), for $i in $doc//tei:rs[@type = 'persons']/string(@key) return tokenize($i, ' ')))
            else functx:value-union($doc//tei:text//tei:persName/string(@key), functx:value-union($doc//tei:text//tei:rs[@type = 'person']/string(@key), for $i in $doc//tei:text//tei:rs[@type = 'persons']/string(@key) return tokenize($i, ' ')))
        else if ($entry eq 'works') then 
            if($isDiary) then functx:value-union($doc//tei:workName/string(@key), functx:value-union($doc//tei:rs[@type eq 'work']/string(@key), for $i in $doc//tei:rs[@type = 'works']/string(@key) return tokenize($i, ' ')))
            else functx:value-union($doc//tei:text//tei:workName/string(@key), functx:value-union($doc//tei:text//tei:rs[@type eq 'work']/string(@key), for $i in $doc//tei:text//tei:rs[@type = 'works']/string(@key) return tokenize($i, ' ')))
        else ()
    return 
        if($suppressDisplay) then ()
        else map { "ids" := distinct-values($coll)[. != ''] }
    (:return if ($coll != '' and not($suppressDisplay)) then (
        for $x in distinct-values($coll)[. != '']
        let $regName := 
            if($entry eq 'person') then wega:getRegName($x)
            else if($entry eq 'work') then wega:getRegTitle($x)
            else ()
        order by $regName ascending
        return 
        <li onclick="highlightSpanClassInText('{$x}',this)">{$regName}</li>
    )
    else (<li class="noDataFound">{wega:getLanguageString('noDataFound',$lang)}</li>):)
};


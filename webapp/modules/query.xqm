xquery version "3.0";

(:~
 : Module for querying the data
 :)
module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
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

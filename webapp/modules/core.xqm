xquery version "3.0";

(:~
 : Core functions of the WeGA-WebApp
 :)
module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace functx="http://www.functx.com" at "functx.xqm";

(:~
 : Get document by ID
 :
 : @author Peter Stadler
 : @param $id the ID of the document
 : @return returns the document node of the resource found for the specified ID.
:)
declare function core:doc($docID as xs:string) as document-node()? {
    let $collectionPath := config:getCollectionPath($docID)
    return 
        if ($collectionPath ne '') then collection($collectionPath)//id($docID)/root() else ()
};

(:~
 : Returns collection (from cache, if possible)
 :
 : @author Peter Stadler
 : @param $collName
 : @param $cacheKey
 : @param $useCache
 : @return node*
 :)
declare function core:getOrCreateColl($collName as xs:string, $cacheKey as xs:string, $useCache as xs:boolean) as document-node()* {
    let $lastModKey := 'lastModDateTime'
    let $dateTimeOfCache := cache:get($collName, $lastModKey)
    let $collCached := cache:get($collName, $cacheKey)
    return
        if(exists($collCached) and not(config:eXistDbWasUpdatedAfterwards($dateTimeOfCache) or $useCache))
        then 
            typeswitch($collCached)
            case xs:string return ()
            default return $collCached
        else
            let $newColl := core:createColl($collName,$cacheKey)
            let $sortedColl := core:sortColl($newColl)
            let $setCache := (cache:put($collName, $lastModKey, current-dateTime()),
                if(exists($newColl)) then cache:put($collName, $cacheKey, $sortedColl)
                else cache:put($collName, $cacheKey, 'empty'))
            let $logMessage := concat('facets:getOrCreateColl(): created collection cache (',$cacheKey,') for ', $collName, ' (', count($newColl), ' items)')
            let $logToFile := core:logToFile('info', $logMessage)
            return $sortedColl
};

(:~
 : helper function for facets:getOrCreateColl and search_getResults.xql
 :
 : @author Peter Stadler
 : @param $collName
 : @param $cacheKey
 : @return node*
 :)
declare function core:createColl($collName as xs:string, $cacheKey as xs:string) as document-node()* {
    let $collPath := string-join(($config:data-collection-path, $collName),'/') 
    let $collPathExists := xmldb:collection-available($collPath) and ($collPath ne '') and ($cacheKey ne '')
    let $isSupportedDiary := if($collName eq 'diaries') then $cacheKey eq 'indices' or $cacheKey eq 'A002068' else true()
    let $predicates :=  if(config:isPerson($cacheKey)) then config:get-option(concat($collName, 'Pred'), $cacheKey)
        else config:get-option(concat($collName, 'PredIndices'))
    return if ($predicates ne '' and $collPathExists and $isSupportedDiary) then util:eval(concat('collection("', $collPath, '")', $predicates)) else()
};

(:~
 : Sort collection
 :
 : @author Peter Stadler 
 : @param $coll collection to be sorted
 : @return item*
 :)
declare function core:sortColl($coll as item()*) as item()* {
    if(config:isPerson($coll[1]/tei:person/string(@xml:id)))            then for $i in $coll order by $i//tei:persName[@type = 'reg'] ascending return $i
    else if(config:isLetter($coll[1]/tei:TEI/string(@xml:id)))          then for $i in $coll order by core:getOneNormalizedDate($i//tei:dateSender/tei:date[1], false()) ascending, $i//tei:dateSender/tei:date[1]/@n ascending return $i
    else if(config:isWriting($coll[1]/tei:TEI/string(@xml:id)))         then for $i in $coll order by core:getOneNormalizedDate($i//tei:imprint/tei:date[1], false()) ascending return $i
    else if(config:isDiary($coll[1]/tei:ab/string(@xml:id)))            then for $i in $coll order by $i/tei:ab/xs:date(@n) ascending return $i
    else if(config:isWork($coll[1]/tei:TEI/string(@xml:id)))            then for $i in $coll order by $i//mei:seriesStmt/mei:title[@level='s']/xs:int(@n) ascending, $i//mei:altId[@type = 'WeV']/string(@subtype) ascending, $i//mei:altId[@type = 'WeV']/xs:int(@n) ascending, $i//mei:altId[@type = 'WeV']/string() ascending return $i
    else if(config:isNews($coll[1]/tei:TEI/string(@xml:id)))            then for $i in $coll order by $i//tei:publicationStmt/tei:date/xs:dateTime(@when) descending return $i
    else if(config:isBiblio($coll[1]/tei:biblStruct/string(@xml:id)))   then for $i in $coll order by core:getOneNormalizedDate($i//tei:imprint/tei:date, false()) descending return $i
    else $coll
};


(:~
 : Write log message to log file
 :
 : @author Peter Stadler
 : @param $priority to be used by util:log-app - e.g. "error"
 : @param $message to write
 : @return 
:)
declare function core:logToFile($priority as xs:string, $message as xs:string) as empty() {
    let $file := config:get-option('errorLogFile')
    let $message := concat($message, ' (rev. ', config:getCurrentSvnRev(), ')')
    return (
        util:log-app($priority, $file, $message),
        if($config:isDevelopment) then util:log-system-out($message)
        else ()
    )
};

(:~
 : Construct one normalized xs:date from a tei:date element's date or duration attributes (@from, @to, @when, @notBefore, @notAfter)
 :  
 : @author Christian Epp
 : @author Peter Stadler
 : @param $date the tei:date
 : @param $latest a boolean whether the constructed date shall be the latest or earliest possible
 : @return the constructed date or empty
 :)
declare function core:getOneNormalizedDate($date as element()?, $latest as xs:boolean) as xs:string? {
    if($date/@when)
        then if($date/@when castable as xs:date) 
            then $date/string(@when)
            else if($date/@when castable as xs:dateTime)
                then substring($date/@when,1,10)
                else core:getCastableDate($date/data(@when), $latest)
        else if($latest)
            then if($date/@notAfter)
                then if($date/@notAfter castable as xs:date)
                    then $date/string(@notAfter)
                    else core:getCastableDate($date/data(@notAfter), $latest)
                else if($date/@notBefore)
                    then if($date/@notBefore castable as xs:date)
                        then $date/string(@notBefore)
                        else core:getCastableDate($date/data(@notBefore), $latest)
                    else if($date/@to)
                        then if($date/@to castable as xs:date)
                            then $date/string(@to)
                            else core:getCastableDate($date/data(@to), $latest)
                        else if($date/@from)
                            then if($date/@from castable as xs:date)
                                then $date/string(@from)
                                else core:getCastableDate($date/data(@from), $latest)
                            else ()
(: Alles nochmal in umgekehrter Reihenfolge, wenn der früheste Zeitpunkt gewünscht ist. :)                                
            else if($date/@notBefore)
                then if($date/@notBefore castable as xs:date)
                    then $date/string(@notBefore)
                    else core:getCastableDate($date/data(@notBefore), $latest)
                else if($date/@notAfter)
                    then if($date/@notAfter castable as xs:date)
                        then $date/string(@notAfter)
                        else core:getCastableDate($date/data(@notAfter), $latest)
                    else if($date/@from)
                        then if($date/@from castable as xs:date)
                            then $date/string(@from)
                            else core:getCastableDate($date/data(@from), $latest)
                        else if($date/@to)
                            then if($date/@from castable as xs:date)
                                then $date/string(@to)
                                else core:getCastableDate($date/data(@to), $latest)
                            else ()
};

(:~
 : Checks, if given $date is castable as xs:date. If it's not castable, but has a length of 4, it will be changed into a date.  
 : 
 : @author Christian Epp
 : @author Peter Stadler
 : @param $node the supposed date node
 : @param $latest is true if the current node has a notAfter-attribute
 : @return the date in right type or empty
 :)
declare function core:getCastableDate($date as xs:string, $latest as xs:boolean) as xs:string? {
    if($date castable as xs:date)
    then $date
    else if($date castable as xs:gYear)
        (:if(string-length($date)=4):)
         then
            if($latest)
            then concat($date,'-12-31')
            else concat($date,'-01-01')
         else()
};

(:~
 : Store some content as file in the db
 : (helper function for wega:grabExternalResource())
 : 
 : @author Peter Stadler
 : @param $collection the collection to put the file in. If empty, the content will be stored in the tmp  
 : @param $fileName the filename of the to be created resource with filename extension
 : @param $contents the content to store. Either a node, an xs:string, a Java file object or an xs:anyURI 
 : @return Returns the path to the newly created resource, empty sequence otherwise
 :)
declare function core:store-file($collection as xs:string?, $fileName as xs:string, $contents as item()) as xs:string? {
    let $collection := 
        if(empty($collection) or ($collection eq '')) then $config:tmp
        else $collection
    let $createCollection := 
        for $coll in tokenize($collection, '/')
        let $parentColl := substring-before($collection, $coll)
        return 
            if(xmldb:collection-available($parentColl || '/' || $coll)) then ''
            else xmldb:create-collection($parentColl, $coll)
    return 
        util:catch(
            '*', 
            xmldb:store($collection, $fileName, $contents), 
            core:logToFile('error', string-join(('wega:storeFileInTmpCollection', $util:exception, $util:exception-message), ' ;; '))
        )
};


(:~
 : format year specification depending on positive or negative value
 :
 : @author Peter Stadler
 : @param $year the year as (positive or negative) integer
 : @param $lang the language switch (en|de)
 : @return xs:string
 :)
declare function core:formatYear($year as xs:int, $lang as xs:string) as xs:string {
    if($year gt 0) then $year cast as xs:string
    else if($lang eq 'en') then concat($year*-1,' BC')
    else concat($year*-1,' v.&#8239;Chr.')
};

(:~
 : String from time
 :
 : @author Peter Stadler
 : @param $format time format
 : @param $value the date
 : @param $lang the language switch (en|de)
 : @return xs:string 
 :)
declare function core:strftime($format as xs:string, $value as xs:date, $lang as xs:string) as xs:string {
    let $day    := day-from-date($value)
    let $month  := month-from-date($value)
    let $year   := core:formatYear(number(year-from-date($value)), $lang)
    let $output := replace($format, '%d', string($day))
    let $output := replace($output, '%Y', string($year))
    let $output := replace($output, '%B', core:getLanguageString(concat('month',$month), $lang))
    let $output := replace($output, '%A', core:getLanguageString(concat('day',datetime:day-in-week($value)), $lang))

    return normalize-space($output)
};

(:~ 
 : Print forename surname
 :
 : @author Peter Stadler
 : @return xs:string
 :)
declare function core:printFornameSurname($name as xs:string?) as xs:string? {
    let $clearName := normalize-space($name)
    return
        if(matches($clearName, ','))
        then normalize-space(string-join(reverse(tokenize($clearName, ',')), ' '))
        else $clearName
};

(:~ 
 : Get the language catalogue file
 :
 : @author Peter Stadler
 : @param the language switch (en|de)
 : @return document-node
 :)
declare function core:getLanguageCatalogue($lang as xs:string) as document-node()? {
    collection($config:catalogues-collection)//tei:text[@type='language-catalogue'][@xml:lang=$lang]/root()
};

(:~
 : Get language string only by key
 :
 : @author Peter Stadler
 : @param $key for the dictionary
 : @param $lang the language of the string (en|de)
 : @return xs:string
 :)
declare function core:getLanguageString($key as xs:string, $lang as xs:string) as xs:string {
    let $catalogue := core:getLanguageCatalogue($lang)
    return normalize-space($catalogue//id($key))
};

(:~
 : Get language string with key and replacements
 :
 : @author Peter Stadler
 : @param $key for the dictionary
 : @param $replacements
 : @param $lang the language of the string (en|de)
 : @return xs:string
 :)
declare function core:getLanguageString($key as xs:string, $replacements as xs:string*, $lang as xs:string) as xs:string {
    let $catalogue := core:getLanguageCatalogue($lang)
    let $catalogueEntry := normalize-space($catalogue//id($key))
    let $replacements := 
        for $r in $replacements 
        return if(string-length($r)<3 and $lang='de' and $key eq 'dateBetween') then concat($r,'.') (: Sonderfall: "Zwischen 3. und 4. März 1767" - Der Punkt hinter der 3 :)
        else $r
    let $placeHolders := 
        for $i at $count in $replacements
        let $x := concat('%',$count)
        return $x
    return functx:replace-multi($catalogueEntry,$placeHolders,$replacements)
};

(:~
 : Tries to do a reverse lookup for a given string and returns its @xml:id 
 : If there are multiple matches they are returned as a sequence, 
 : if no translation is found the empty string is returned
 :  
 : @author Peter Stadler
 : @param $string the string to lookup
 : @param $lang the language of the given string
 : @return xs:NCName* zero or more IDs
 :)
declare function core:reverseLanguageStringLookup($string as xs:string, $lang as xs:string) as xs:string* {
    let $catalogue := core:getLanguageCatalogue($lang)
    return $catalogue//tei:item[lower-case(.) eq lower-case($string)]/string(@xml:id)
};

(:~
 : Tries to translate a string from sourceLang to targetLang using the dictionaries 
 : If no translation is found the empty string is returned
 :  
 : @author Peter Stadler
 : @param $string the string to translate
 : @param $sourceLang the language to translate from
 : @param $targetLang the language to translate to
 : @return xs:string the translated string if successfull, otherwise the empty string
 :)
declare function core:translateLanguageString($string as xs:string, $sourceLang as xs:string, $targetLang as xs:string) as xs:string {
    let $targetCatalogue := core:getLanguageCatalogue($targetLang)
    let $search := $targetCatalogue//id(core:reverseLanguageStringLookup($string, $sourceLang))[1]
    return normalize-space($search)
};

(:~
 : Does a dictionary lookup and returns this value 
 : 
 : @author Peter Stadler
 : @param $key the key to look for in the dictionary
 : @param $dicID the xml:id of the dictionary to search in
 : @return xs:String
 :)
(:declare function core:dictionaryLookup($key as xs:string, $dicID as xs:string) as xs:string {
    let $dic := doc(config:get-option($dicID))
    return normalize-space($dic//id($key))
};:)

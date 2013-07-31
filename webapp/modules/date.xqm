xquery version "3.0";

(:~
 : XQuery module for processing dates
 :)
module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";

(:~
 : Construct one normalized xs:date from a tei:date element's date or duration attributes (@from, @to, @when, @notBefore, @notAfter)
 :  
 : @author Christian Epp
 : @author Peter Stadler
 : @param $date the tei:date
 : @param $latest a boolean whether the constructed date shall be the latest or earliest possible
 : @return the constructed date or empty
 :)
declare function date:getOneNormalizedDate($date as element()?, $latest as xs:boolean) as xs:string? {
    if($date/@when)
        then if($date/@when castable as xs:date) 
            then $date/string(@when)
            else if($date/@when castable as xs:dateTime)
                then substring($date/@when,1,10)
                else date:getCastableDate($date/data(@when), $latest)
        else if($latest)
            then if($date/@notAfter)
                then if($date/@notAfter castable as xs:date)
                    then $date/string(@notAfter)
                    else date:getCastableDate($date/data(@notAfter), $latest)
                else if($date/@notBefore)
                    then if($date/@notBefore castable as xs:date)
                        then $date/string(@notBefore)
                        else date:getCastableDate($date/data(@notBefore), $latest)
                    else if($date/@to)
                        then if($date/@to castable as xs:date)
                            then $date/string(@to)
                            else date:getCastableDate($date/data(@to), $latest)
                        else if($date/@from)
                            then if($date/@from castable as xs:date)
                                then $date/string(@from)
                                else date:getCastableDate($date/data(@from), $latest)
                            else ()
(: Alles nochmal in umgekehrter Reihenfolge, wenn der früheste Zeitpunkt gewünscht ist. :)                                
            else if($date/@notBefore)
                then if($date/@notBefore castable as xs:date)
                    then $date/string(@notBefore)
                    else date:getCastableDate($date/data(@notBefore), $latest)
                else if($date/@notAfter)
                    then if($date/@notAfter castable as xs:date)
                        then $date/string(@notAfter)
                        else date:getCastableDate($date/data(@notAfter), $latest)
                    else if($date/@from)
                        then if($date/@from castable as xs:date)
                            then $date/string(@from)
                            else date:getCastableDate($date/data(@from), $latest)
                        else if($date/@to)
                            then if($date/@from castable as xs:date)
                                then $date/string(@to)
                                else date:getCastableDate($date/data(@to), $latest)
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
declare function date:getCastableDate($date as xs:string, $latest as xs:boolean) as xs:string? {
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
 : format year specification depending on positive or negative value
 :
 : @author Peter Stadler
 : @param $year the year as (positive or negative) integer
 : @param $lang the language switch (en|de)
 : @return xs:string
 :)
declare function date:formatYear($year as xs:int, $lang as xs:string) as xs:string {
    if($year gt 0) then $year cast as xs:string
    else if($lang eq 'en') then concat($year*-1,' BC')
    else concat($year*-1,' v.&#8239;Chr.')
};

(:~
 : String from date
 :
 : @author Peter Stadler
 : @param $format time format
 : @param $value the date
 : @param $lang the language switch (en|de)
 : @return xs:string 
 :)
declare function date:strfdate($format as xs:string, $value as xs:date, $lang as xs:string) as xs:string {
    let $day    := day-from-date($value)
    let $month  := month-from-date($value)
    let $year   := date:formatYear(number(year-from-date($value)), $lang)
    let $output := replace($format, '%d', string($day))
    let $output := replace($output, '%Y', string($year))
    let $output := replace($output, '%B', core:getLanguageString(concat('month',$month), $lang))
    let $output := replace($output, '%A', core:getLanguageString(concat('day',datetime:day-in-week($value)), $lang))

    return normalize-space($output)
};

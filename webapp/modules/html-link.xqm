xquery version "3.0";

(:~
 : XQuery module for generating HTML links
 : (these will be called by the HTML templates)
 :)
module namespace html-link="http://xquery.weber-gesamtausgabe.de/modules/html-link";

(:declare namespace repo="http://exist-db.org/xquery/repo";:)
(:declare namespace expath="http://expath.org/ns/pkg";:)
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

(:import module namespace templates="http://exist-db.org/xquery/templates";:)
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";

(:~
 : Creates person link
 :
 : @author Peter Stadler
 : @param $id of the person
 : @param $lang the current language (de|en)
 : @param $order (sf|fs) whether to print "surname, forename" or "forename surname"
 : @return HTML element
 :)
declare function html-link:createPersonLink($id as xs:string, $lang as xs:string, $order as xs:string) as element() {
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
declare function html-link:createDocLink($doc as document-node(), $content as xs:string, $lang as xs:string, $attributes as xs:string*) as element() {
    let $href := html-link:createLinkToDoc($doc, $lang)
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
declare function html-link:createLinkToDoc($doc as document-node(), $lang as xs:string) as xs:string? {
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

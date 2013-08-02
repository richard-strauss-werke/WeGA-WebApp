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

import module namespace templates="http://exist-db.org/xquery/templates" at "/db/apps/shared-resources/content/templates.xql";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";

(:~
 : Serves as a shortcut to templates:link-to-app()
 : The assumed context is the current app
 :
 : @author Peter Stadler
 : @param $relLink a relative path to be added to the returned path
 : @return the complete URL for $relLink
 :)
declare function html-link:link-to-current-app($relLink as xs:string?) as xs:string {
(:    templates:link-to-app($config:expath-descriptor/@name, $relLink):)
    replace(string-join((request:get-context-path(), request:get-attribute("$exist:prefix"), 'WeGA-WebApp', $relLink), "/"), "/+", "/")
};

(:~
 : Creates an absolute path to doc
 :
 : @author Peter Stadler
 : @param $doc document node
 : @param $lang the current language (de|en)
 : @return xs:string
:)
declare function html-link:create-href-for-doc($doc as document-node(), $lang as xs:string) as xs:string? {
    let $docID :=  $doc/*/@xml:id
    let $docType := config:getDoctypeByID($docID)
    let $authorId := query:getAuthorIDOfDoc($doc)
    let $folder := 
        if($docType eq 'letters') then core:getLanguageString('correspondence', $lang) (: Ausnahme für Briefe=Korrespondenz:)
        else if(exists($docType)) then core:getLanguageString($docType, $lang)
        else ()
    return 
        if($docType eq 'persons') then html-link:link-to-current-app(string-join(($lang, $docID), '/')) (: Ausnahme für Personen, die direkt unter {baseref}/{lang}/ angezeigt werden:)
        else if($docType eq 'works') then ()        (: Currently not implemented :)
        else if($docType eq 'iconography') then ()  (: Currently not implemented :)
        else if($docType eq 'biblio') then ()       (: Currently not implemented :)
        else if($docType eq 'var') then ()          (: Currently not implemented :)
        else if(exists($folder) and $authorId ne '') then html-link:link-to-current-app(string-join(($lang, $authorId, $folder, $docID), '/'))
        else ()
};

(:~
 : Creates an xhtml:a element for a given document
 :
 : @author Peter Stadler
 : @param $doc the document to create the link for
 : @param $content the string content for the xhtml a element
 : @param $lang the language switch (en, de)
 : @param $attributes a sequence of attribute-value-pairs, e.g. ('class=xy', 'style=display:block')
 :)
declare function html-link:create-a-for-doc($doc as document-node(), $content as xs:string, $lang as xs:string, $attributes as xs:string*) as element(xhtml:a) {
    let $href := html-link:create-href-for-doc($doc, $lang)
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

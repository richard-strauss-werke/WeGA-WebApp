xquery version "3.0";

(:~
 : XQuery module for transforming TEI to XHTML 
 : Elements from the TEI module linking
 :)
module namespace tei2html-namesdates="http://xquery.weber-gesamtausgabe.de/modules/tei2html-namesdates";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

(:import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";:)
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace tei2html="http://xquery.weber-gesamtausgabe.de/modules/tei2html" at "tei2html.xqm";
(:import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";:)
import module namespace html-link="http://xquery.weber-gesamtausgabe.de/modules/html-link" at "html-link.xqm";

declare function tei2html-namesdates:persName($node as element(tei:persName), $lang as xs:string)  as element() {
    if($node/@key) then html-link:create-a-for-doc(core:doc($node/@key), normalize-space($node), $lang, ())
    else tei2html:process($node/node(), $lang)
};

(:declare function tei2html-namesdates:orgName($node as element(tei:orgName), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-namesdates:region($node as element(tei:region), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-namesdates:country($node as element(tei:country), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-namesdates:placeName($node as element(tei:placeName), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-namesdates:settlement($node as element(tei:settlement), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
:)

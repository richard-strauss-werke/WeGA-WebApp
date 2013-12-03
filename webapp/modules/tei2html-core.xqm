xquery version "3.0";

(:~
 : XQuery module for transforming TEI to XHTML 
 : Elements from the TEI module linking
 :)
module namespace tei2html-core="http://xquery.weber-gesamtausgabe.de/modules/tei2html-core";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

(:import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";:)
(:import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";:)
(:import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";:)
(:import module namespace html-link="http://xquery.weber-gesamtausgabe.de/modules/html-link" at "html-link.xqm";:)

(:
declare function tei2html-core:address($node as element(tei:address), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:addrLine($node as element(tei:addrLine), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:hi($node as element(tei:hi), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};

declare function tei2html-core:p($node as element(tei:p), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:abbr($node as element(tei:abbr), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:title($node as element(tei:title), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:name($node as element(tei:name), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:milestone($node as element(tei:milestone), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};

declare function tei2html-core:lg($node as element(tei:lg), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:num($node as element(tei:num), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:bibl($node as element(tei:bibl), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:cit($node as element(tei:cit), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:quote($node as element(tei:quote), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:label($node as element(tei:label), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:l($node as element(tei:l), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:date($node as element(tei:date), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:corr($node as element(tei:corr), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:unclear($node as element(tei:unclear), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:add($node as element(tei:add), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:sic($node as element(tei:sic), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:gap($node as element(tei:gap), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:list($node as element(tei:list), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:item($node as element(tei:item), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:pb($node as element(tei:pb), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:lb($node as element(tei:lb), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:del($node as element(tei:del), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:choice($node as element(tei:choice), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};

declare function tei2html-core:expan($node as element(tei:expan), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:rs($node as element(tei:rs), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};

declare function tei2html-core:ref($node as element(tei:ref), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};

declare function tei2html-core:ptr($node as element(tei:ptr), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:note($node as element(tei:note), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:author($node as element(tei:author), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};

declare function tei2html-core:head($node as element(tei:head), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
declare function tei2html-core:graphic($node as element(tei:graphic), $lang as xs:string)  as element(xhtml:span) {
    element xhtml:span {
        tei2html:main($node/node(), $lang)
    }
};
:)
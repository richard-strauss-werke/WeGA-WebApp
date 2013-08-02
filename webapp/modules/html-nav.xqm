xquery version "3.0";

(:~
 : XQuery module for generating navigation elements 
 : (these will be called by the HTML templates)
 :)
module namespace html-nav="http://xquery.weber-gesamtausgabe.de/modules/html-nav";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace html-link="http://xquery.weber-gesamtausgabe.de/modules/html-link" at "html-link.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";

(:~
 : Top navigation for all pages 
 :
 : @author Peter Stadler
 : @return html:div 
 :)
declare function html-nav:page-top-bar-section($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:section) {
    let $html_pixDir := config:get-option('pixDir')
    let $uriTokens := tokenize(xmldb:decode-uri(request:get-uri()), '/')
    let $search := html-link:link-to-current-app(string-join(($lang, lang:get-language-string('search', $lang)), '/'))
    let $index := html-link:link-to-current-app(string-join(($lang, lang:get-language-string('index', $lang)), '/'))
    let $impressum := html-link:link-to-current-app(string-join(($lang, lang:get-language-string('about', $lang)), '/'))
    let $help := html-link:link-to-current-app(string-join(($lang, lang:get-language-string('help', $lang)), '/'))
    let $switchLanguage := 
        for $i in $uriTokens[string-length(.) gt 2]
        return
            if (matches($i, 'A\d{6}')) then $i
            else if($lang eq 'en') then replace(lang:translate-language-string(replace($i, '_', ' '), $lang, 'de'), '\s', '_') (: Ersetzen von Leerzeichen durch Unterstriche in der URL :)
            else replace(lang:translate-language-string(replace($i, '_', ' '), $lang, 'en'), '\s', '_')
    let $switchLanguage := if($lang eq 'en')
        then <a href="{html-link:link-to-current-app(string-join(('de', $switchLanguage), '/'))}" title="Diese Seite auf Deutsch"><img src="{html-link:link-to-current-app(string-join(($html_pixDir, 'de.gif'), '/'))}" alt="germanFlag" width="20" height="12"/></a>
        else <a href="{html-link:link-to-current-app(string-join(('en', $switchLanguage), '/'))}" title="This page in english"><img src="{html-link:link-to-current-app(string-join(($html_pixDir, 'gb.gif'), '/'))}" alt="englishFlag" width="20" height="12"/></a>
    return 
    element section {
        attribute class {"top-bar-section"},
        (:if(config:get-option('environment') eq 'development') then attribute class {'dev'}
        else if(config:get-option('environment') eq 'release') then attribute class {'rel'}
        else (),
        <h1><a href="{$index}"><span class="hiddenLink">Carl Maria von Weber Gesamtausgabe</span></a></h1>,:)
        <ul class="left">
            <li class="has-form">
                <form>
                    <div class="row collapse">
                        <div class="small-8 columns">
                            <input type="text"/>
                        </div>
                        <div class="small-4 columns">
                            <a href="#" class="small button">Search</a>
                        </div>
                    </div>
                </form>
            </li>
        </ul>,
        <ul class="right">
            <li><a href="{$index}">{lang:get-language-string('home',$lang)}</a></li>
            <li class="divider"></li>
            <li><a href="{$impressum}">{lang:get-language-string('about',$lang)}</a></li>
            <li class="divider"></li>
            <li><a href="{$help}">{lang:get-language-string('help',$lang)}</a></li>
            <li class="divider"></li>
            <li>{$switchLanguage}</li>
        </ul>
    }
};

(:~
 : Sub navigation for the index and error pages 
 :
 : @author Peter Stadler
 : @return html:div 
 :)
declare function html-nav:page-nav-digital-edition($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    <div id="page-nav-digital-edition" xmlns="http://www.w3.org/1999/xhtml">
        <h3>{lang:get-language-string('digitalEdition', $lang)}</h3>
        <ul>
            <li><a href="{html-link:link-to-current-app($lang || '/A002068')}">Weber Person</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, 'A002068', lang:get-language-string('correspondence', $lang)), '/'))}">Weber {lang:get-language-string('correspondence', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, 'A002068', lang:get-language-string('diaries', $lang)), '/'))}">Weber {lang:get-language-string('diaries', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, 'A002068', lang:get-language-string('writings', $lang)), '/'))}">Weber {lang:get-language-string('writings', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, 'A002068', lang:get-language-string('works', $lang)), '/'))}">Weber {lang:get-language-string('works', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, lang:get-language-string('indices', $lang)), '/'))}">{lang:get-language-string('indices', $lang)}</a></li>
        </ul>
    </div>
};

(:~
 : Sub navigation for the index and error pages
 :
 : @author Peter Stadler
 : @return html:div 
 :)
declare function html-nav:page-nav-project-links($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    <div id="page-nav-project-links" xmlns="http://www.w3.org/1999/xhtml">
        <h3>{lang:get-language-string('aboutTheProject', $lang)}</h3>
        <ul>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, lang:get-language-string('indices',$lang), lang:get-language-string('news',$lang)),'/'))}">{lang:get-language-string('news', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, replace(lang:get-language-string('editorialGuidelines',$lang), '\s', '_')),'/'))}">{lang:get-language-string('editorialGuidelines', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, replace(lang:get-language-string('projectDescription',$lang), '\s', '_')), '/'))}">{lang:get-language-string('projectDescription', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, lang:get-language-string('publications',$lang)), '/'))}">{lang:get-language-string('publications', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, lang:get-language-string('bibliography',$lang)), '/'))}">{lang:get-language-string('bibliography', $lang)}</a></li>
            <li><a href="{html-link:link-to-current-app(string-join(($lang, lang:get-language-string('contact',$lang)), '/'))}">{lang:get-language-string('contact', $lang)}</a></li>
        </ul>
    </div>
};


(:~
 : Sub navigation for the index and error pages
 :
 : @author Peter Stadler
 : @return html:div 
 :)
declare function html-nav:page-nav-dev-links($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    <div id="page-nav-dev-links" xmlns="http://www.w3.org/1999/xhtml">{
        element h3 {lang:get-language-string('development', $lang)},
        element ul {
            element li {
                element a {
                    attribute href {html-link:link-to-current-app(string-join(($lang, lang:get-language-string('tools', $lang)), '/'))},
                    'Tools'
                }
            }
        }
    }
    </div>
};

declare function html-nav:page-nav-combined($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {
    <div class="section-container accordion" data-section="" data-options="one_up: false;" xmlns="http://www.w3.org/1999/xhtml">
        <section class="section">
            <p class="title" data-section-title=""><a href="#">{lang:get-language-string('digitalEdition', $lang)}</a></p>
            <div class="content" data-section-content="">
                <ul class="side-nav">
                    {html-nav:page-nav-digital-edition($node, $model, $lang)//xhtml:li}
                </ul>
            </div>
        </section>
        <section class="section">
            <p class="title" data-section-title=""><a href="#">{lang:get-language-string('aboutTheProject', $lang)}</a></p>
            <div class="content" data-section-content="">
                <ul class="side-nav">
                    {html-nav:page-nav-project-links($node, $model, $lang)//xhtml:li}
                </ul>
            </div>
        </section>
    </div>
};

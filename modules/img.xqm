xquery version "3.0" encoding "UTF-8";

(:~
: Collected xQuery functions
:
: @author Peter Stadler 
: @version 1.0
:)

module namespace img="http://xquery.weber-gesamtausgabe.de/modules/img";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace image="http://exist-db.org/xquery/image" at "java:org.exist.xquery.modules.image.ImageModule";
import module namespace functx="http://www.functx.com";

(:~
 : Gets portrait path for digilib
 :  
 : @author Peter Stadler
 : @param $person node of a certain person
 : @param $dimensions of image
 : @param $lang the language of the string (en|de)
 : @return xs:string
 :)
declare function img:getPortraitPath($person as element(tei:person), $dimensions as xs:integer+, $lang as xs:string) as xs:string? {
    let $docID := $person/data(@xml:id)
    let $pnd := $person/tei:idno[@type='gnd']
    let $unknownWoman := config:get-option('unknownWoman')
    let $unknownMan := config:get-option('unknownMan')
    let $unknownSex := config:get-option('unknownSex')
    let $localPortrait := core:getOrCreateColl('iconography', $docID, true())//tei:figure[@n='portrait'][1]
    let $cachedPortrait := doc(concat($config:tmp-collection-path, replace($docID, '\d{2}$', 'xx'), '/', $docID, '.xml'))//localFile/string()
    let $graphicURL := 
        if($localPortrait/tei:graphic[1]/data(@url)) then core:join-path-elements((substring-after(config:getCollectionPath($docID), $config:data-collection-path || '/'), $docID, $localPortrait/tei:graphic[1]/data(@url)))
        else if($localPortrait) then () (: there is a figure but no graphic --> we want to display generic portraits :)
        else if(util:binary-doc-available($cachedPortrait)) then $cachedPortrait
        else if(exists($pnd)) then img:retrieveImagesFromWikipedia(string($pnd), $lang)//wega:wikipediaImage[1]/wega:localUrl/text()
        else ()
    return 
        if(exists($graphicURL)) then img:createDigilibURL($graphicURL, $dimensions, true())
        else if(data($person//tei:sex)='f') then img:createDigilibURL($unknownWoman, $dimensions, true()) 
        else if(data($person//tei:sex)='m') then img:createDigilibURL($unknownMan, $dimensions, true()) 
        else img:createDigilibURL($unknownSex, $dimensions, true())
};


(:~
 : Get portrait (i.e. the first picture on the page) from an wikipedia article
 :
 : @author Peter Stadler 
 : @param $pnd the PND number
 : @param $lang the language variable (de|en)
 : @return element the local path to the stored file
 :)
declare function img:retrieveImagesFromWikipedia($pnd as xs:string, $lang as xs:string) as element(wega:wikipediaImages) {
    let $wikiArticle := wega:grabExternalResource('wikipedia', $pnd, $lang, true())
    let $pics := $wikiArticle//xhtml:div[@class='thumbinner']
    return 
        <wega:wikipediaImages>{
            for $div in $pics
            let $caption := normalize-space(concat($div/xhtml:div[@class='thumbcaption'],' (', lang:get-language-string('sourceWikipedia', $lang), ')'))
            let $tmpPicURI := $div//xhtml:img[@class='thumbimage']/string(@src)
            let $picURI := (: Achtung: in $pics landen auch andere Medien, z.B. audio. Diese erzeugen dann aber ein leeres $tmpPicURI, da natürlich kein <img/> vorhanden :)
                if(starts-with($tmpPicURI, '//')) then concat('http:', $tmpPicURI) 
                else if(starts-with($tmpPicURI, 'http')) then $tmpPicURI
                else ()
            let $localURL := if($picURI castable as xs:anyURI) then img:retrievePicture(xs:anyURI($picURI), ()) else ()
            return if(exists($localURL)) then
                <wega:wikipediaImage>
                    <wega:caption>{$caption}</wega:caption>
                    <wega:orgUrl>{$picURI}</wega:orgUrl>
                    <wega:localUrl>{$localURL}</wega:localUrl>
                </wega:wikipediaImage>
                else ()
        }</wega:wikipediaImages>
};

(:~
 : Retrieve a picture from any URI and store it in the database
 :
 : @author Peter Stadler
 : @param $picURL the URL to the file as xs:string
 : @param $localName the fileName within the local db. If empty, a hash of the $picURL will be taken as fileName
 : @return xs:string the local path to the stored file 
 :)
declare function img:retrievePicture($picURL as xs:anyURI, $localName as xs:string?) as xs:string? {
    let $suffix := lower-case(functx:substring-after-last($picURL, '.'))
    let $localFileName :=  
        if(matches($localName, '\S')) then $localName
        else util:hash($picURL, 'md5')
    let $localDbCollection := 
        if(matches($localFileName, '^A\d{6}$')) then 
            if(xmldb:collection-available(concat($config:tmp-collection-path, replace($localFileName, '\d{2}$', 'xx')))) then concat($config:tmp-collection-path, replace($localFileName, '\d{2}$', 'xx'))
            else xmldb:create-collection($config:tmp-collection-path, replace($localFileName, '\d{2}$', 'xx'))
        else if(xmldb:collection-available(concat($config:tmp-collection-path, replace($localFileName, '^(\w{2})\w+', '$1xxx')))) then concat($config:tmp-collection-path, replace($localFileName, '^(\w{2})\w+', '$1xxx'))
            else xmldb:create-collection($config:tmp-collection-path, replace($localFileName, '^(\w{2})\w+', '$1xxx'))
    let $pathToLocalFile := concat($localDbCollection, '/', $localFileName, '.', $suffix)
    let $storeFile := 
        if (util:binary-doc-available($pathToLocalFile)) then () 
        else
            try { xmldb:store($localDbCollection, concat($localFileName, '.', $suffix), xs:anyURI($picURL)) }
            catch * { core:logToFile('error', string-join(('img:retrievePicture', $err:code, $err:description, 'URL: ' || $picURL), ' ;; ')) }
    let $picMetaData := 
        if(img:getPicMetadata($pathToLocalFile)) then img:getPicMetadata($pathToLocalFile) (: Wenn Metadaten schon vorhanden sind, brauchen sie nicht erneut angelegt werden :)
        else core:cache-doc(concat(functx:substring-before-last($pathToLocalFile, '.'), '.xml'), img:createPicMetadata#2, ($pathToLocalFile, $picURL), false())
    return 
        if (util:binary-doc-available($pathToLocalFile) and $picMetaData) then $pathToLocalFile (: Datei bereits vorhanden :)
        else ()
};

(:~
 : Stores picture meta data
 :
 : @author Peter Stadler
 : @param $pathToLocalFile
 : @param $origURL
 : @return xs:string?
 :)
declare function img:createPicMetadata($pathToLocalFile as xs:string, $origURL as xs:anyURI) as element(picMetadata) {
(:    let $localDbCollection := functx:substring-before-last($pathToLocalFile, '/'):)
(:    let $localFileName := functx:substring-after-last($pathToLocalFile, '/'):)
    let $picHeight :=
        try { image:get-height(util:binary-doc($pathToLocalFile)) }
        catch * { core:logToFile('error', string-join(('img:createPicMetadata', $err:code, $err:description, 'pathToLocalFile: ' || $pathToLocalFile), ' ;; ')) }
    let $picWidth := 
        try { image:get-width(util:binary-doc($pathToLocalFile)) }
        catch * { core:logToFile('error', string-join(('img:createPicMetadata', $err:code, $err:description, 'pathToLocalFile: ' || $pathToLocalFile), ' ;; ')) }
    return
        <picMetadata>
            <localFile>{$pathToLocalFile}</localFile>
            <origURL>{$origURL}</origURL>
            <width>{if($picWidth instance of xs:integer) then concat($picWidth, 'px') else ()}</width>
            <height>{if($picHeight instance of xs:integer) then concat($picHeight, 'px') else ()}</height>
        </picMetadata>
};

(:~
 : Gets picture meta data
 :
 : @author Peter Stadler
 : @param $pathToLocalFile
 : @param $origURL
 : @return xs:string?
 :)
declare function img:getPicMetadata($localPicURL as xs:string) as element(picMetadata)? {
    let $unknownWoman := config:get-option('unknownWoman')
    let $unknownMan := config:get-option('unknownMan')
    let $unknownSex := config:get-option('unknownSex')
    let $picFileName := functx:substring-after-last($localPicURL, '/')
    let $localMetadataURL := concat(functx:substring-before-last($localPicURL, '.'), '.xml')
    return 
        if (doc-available($localMetadataURL)) then doc($localMetadataURL)/picMetadata
        else if($localPicURL = ($unknownMan, $unknownWoman, $unknownSex)) then
            <picMetadata>
                <localFile>{$localPicURL}</localFile>
                <origURL/>
                <width>140px</width>
                <height>185px</height>
            </picMetadata>
        else if(core:getOrCreateColl('iconography', 'indices', true())//tei:graphic[@url = $picFileName]) then 
            let $metadataFile := core:getOrCreateColl('iconography', 'indices', true())//tei:graphic[@url = $picFileName]
            return
                <picMetadata>
                    <localFile>{$localPicURL}</localFile>
                    <origURL/>
                    <width>{$metadataFile/normalize-space(@width)}</width>
                    <height>{$metadataFile/normalize-space(@height)}</height>
                </picMetadata>
        else ()
};

(:~
 : Creates digilib URL
 :
 : @author Peter Stadler
 : @param $localPicURL
 : @param $dimensions of image
 : @param $trim 
 : @return xs:string?
 :)
declare function img:createDigilibURL($localPicURL as xs:string, $dimensions as xs:integer+, $trim as xs:boolean) as xs:string? {
    let $picMetadata := img:getPicMetadata($localPicURL)
    let $picHeight := if(substring-before($picMetadata/height, 'px') castable as xs:int) then xs:int(substring-before($picMetadata/height, 'px')) else 1
    let $picWidth := if(substring-before($picMetadata/width, 'px') castable as xs:int) then xs:int(substring-before($picMetadata/width, 'px')) else 1
    let $dw := $dimensions[1]
    let $dh := $dimensions[2]
    let $ratioW := $picWidth div $dw
    let $ratioH := $picHeight div $dh
    let $ww := if(($ratioW gt $ratioH) and $trim) 
        then round-half-to-even($ratioH div $ratioW, 2)
        else 1
    let $wh := if(($ratioH gt $ratioW) and $trim) 
        then round-half-to-even($ratioW div $ratioH, 2)
        else 1
    let $wx := (1 - $ww) div 2
    let $digilibParams := concat('&#38;dw=', string($dw), '&#38;dh=', string($dh), '&#38;ww=', string($ww), '&#38;wh=', string($wh), '&#38;wx=', string($wx), '&#38;mo=q2,png')
    return
        img:replace-url-for-digilib($localPicURL, $digilibParams)
};

(:~
 : Creates digilib URL
 :
 : @author Peter Stadler
 : @param $localPicURL
 : @param $crop
 : @return xs:string? 
 :)
declare function img:createDigilibURL($localPicURL as xs:string, $crop as xs:boolean) as xs:string? {
    let $digilibParams := if($crop)
        then '&#38;dw=400&#38;dh=600'
        else '&#38;mo=file'
    return
        img:replace-url-for-digilib($localPicURL, $digilibParams)
};

declare %private function img:replace-url-for-digilib($localPicURL as xs:string, $digilibParams as xs:string) as xs:string {
    let $digilibDir := config:get-option('digilibDir')
    let $digilibURL :=
        (: case 1: Images are stored in $config:tmp-collection-path :)
        if(starts-with($localPicURL, $config:tmp-collection-path)) then concat(replace($localPicURL, $config:app-root || '/', $digilibDir), $digilibParams)
        
        (: case 2: Images are stored under $config:app-root/resources/pix :)
        else if(starts-with($localPicURL, $config:app-root || '/resources')) then concat(replace($localPicURL, $config:app-root || '/', $digilibDir), $digilibParams)
        
        (: case 3: Images are stored in the filesystem :)
        else $digilibDir || $localPicURL || $digilibParams
       
    return 
        replace($digilibURL, '/+', '/')
};


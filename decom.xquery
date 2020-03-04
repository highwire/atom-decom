import module namespace dba = "org.highwire.hpp.dba-update" at "/reprocessing/lib/lib-dba-update.xqy";

declare namespace hw="org.highwire.hpp";
declare namespace atom="http://www.w3.org/2005/Atom";

declare variable $server as xs:string external;
declare variable $corpus as xs:string external;

declare variable $svc-atom as xs:string := '/svc.atom';

(: You must explicitly change this to false() to delete a corpus :)
declare variable $dry-run as xs:boolean := true();

declare variable $directory as xs:string := concat('/',$corpus,'/');
declare variable $corpus-atom as xs:string := concat('/',$corpus,'.atom');

(: Make sure that the corpus argument is not nil :)
if ($corpus eq '') 
then error(xs:QName('bad-corpus'),'corpus must not be nil')
else (),

(: Allow this to run for up to one hour :)
xdmp:set-request-time-limit(3600),

<report xml:base="{$server}" at="{current-dateTime()}" xmlns:hw="org.highwire.hpp">{
(: For all the non-deleted nodes in the corpus, and then the corpus atom... :)
for $f in (
  xdmp:directory($directory,'infinity')/hw:doc[hw:resource-meta[not(@status eq 'deleted')]],
  doc($corpus-atom)/hw:doc
)
let
  $uri := base-uri($f),
  $resource-meta-old := $f/hw:resource-meta,
  (: construct a new hw:resource-meta reflecting the deletion status :)
  $resource-meta-new := element{'hw:resource-meta'}{attribute{'status'}{'deleted'},$resource-meta-old/(@created,@updated),attribute{'deleted'}{current-dateTime()}},
  (: find the things that are not the hw:resource-meta to delete :)
  $delete := $f/*[not(. is $resource-meta-old)]
order by $uri
return
  <node href="{$uri}" deleted="{not($dry-run)}">{
    if ($dry-run)
    then ($resource-meta-old,$resource-meta-new)
    else (
      (: delete the content stuff to be deleted :) 
      (for $n in $delete return xdmp:node-delete($n)),
      (: update the hw:resource-meta :)
      xdmp:node-replace($resource-meta-old,$resource-meta-new),
      $resource-meta-new
    )
  }</node>,

(: remove the child link to the corpus from the svc.atom :)
let
  $corpus-link as element(atom:link)? := doc($svc-atom)/hw:doc/atom:entry/atom:link[@rel eq 'http://schema.highwire.org/Compound#child'][@href eq $corpus-atom]
return
  if (exists($corpus-link))
  then 
    <svc-link deleted="{not($dry-run)}">{
    if ($dry-run)
    then $corpus-link
    else (
      (: update the app:edited value for the svc.atom :)
      dba:update-metadata($svc-atom),
      (: remove the corpus link :)
      xdmp:node-delete($corpus-link),
      $corpus-link
    )
    }</svc-link>
  else ()
}</report>
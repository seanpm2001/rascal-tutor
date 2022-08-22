@bootstrapParser
module  lang::rascal::tutor::apidoc::ExtractInfo

import String;
import lang::rascal::\syntax::Rascal;
import ParseTree;
import util::Reflective;

import lang::rascal::tutor::apidoc::DeclarationInfo;

@doc{Extract declaration information from a Rascal module at given location.}
list[DeclarationInfo] extractInfo(loc moduleLoc){
    M = parseModuleWithSpaces(moduleLoc).top;
    return extractModule(M);
}

list[DeclarationInfo] extractModule(m: (Module) `<Header header> <Body body>`) {
    moduleName = "<header.name>";
    tags = getTags(header.tags);
    tls = [ *extractTopLevel(moduleName, tl) |  tl <- body.toplevels ];

    content = trim(tags["doc"] ? "") + trim((!(tags["doc"]?)) ? contentFromTags(tags) : "");
    synopsis = getSynopsis(tags, content);

    return moduleInfo(moduleName, m@\loc, synopsis, content) + tls;
}

str contentFromTags(map[str,str] tags) 
  = "<if (tags["synopsis"]?) {>### Synopsis
    '<trim(tags["synopsis"])><}>
    '<if (tags["details"]?) {>### Details
    '<trim(tags["details"])><}>
    '<if (tags["types"]?) {>### Types
    '<trim(tags["types"])><}>
    '<if (tags["description"]?) {>### Description
    '<trim(tags["description"])><}>
    '<if (tags["examples"]?) {>### Examples
    '<trim(tags["examples"])><}>
    '<if (tags["benefits"]?) {>### Benefits
    '<trim(tags["benefits"])><}>
    '<if (tags["pitfalls"]?) {>### Pitfalls
    '<trim(tags["pitfalls"])><}>
    ";

/********************************************************************/
/*                  Process declarations in a module                */
/********************************************************************/
    
list[DeclarationInfo] extractTopLevel(str moduleName, (Toplevel) `<Declaration decl>`) = extractDecl(moduleName, decl);

// -- variable declaration ------------------------------------------

list[DeclarationInfo]  extractDecl(str moduleName, d: (Declaration) `<Tags tags> <Visibility visibility> <Type tp> <{Variable ","}+ variables> ;`) {  
    return [];
}       

// -- miscellaneous declarations ------------------------------------

list[DeclarationInfo]  extractDecl(str moduleName, d: (Declaration) `<Tags tags> <Visibility visibility> anno <Type annoType> <Type onType>@<Name name> ;`) = [  ];

list[DeclarationInfo]  extractDecl(str moduleName, d: (Declaration) `<Tags tags> <Visibility visibility> alias <UserType user> = <Type base> ;`) {
     dtags = getTags(tags);
     content = trim(dtags["doc"] ? "");
     return [ aliasInfo(moduleName, "<user>", "<base>", d@\loc, getSynopsis(dtags, content), content) ];
}

list[DeclarationInfo]  extractDecl(str moduleName, d: (Declaration) `<Tags tags> <Visibility visibility> tag <Kind kind> <Name name> on <{Type ","}+ types> ;`)  = [ ];

list[DeclarationInfo]  extractDecl(str moduleName, d: (Declaration) `<Tags tags> <Visibility visibility> data <UserType user> ;`)  = [ ];

str align({Variant "|"}+ variants){
   res = "";
   sep = "\n     = ";
   for(v <- variants){
       res += sep + trim("<v>");
       sep = "\n     | ";
   }
   return res + "\n     ;";
}

list[DeclarationInfo]  extractDecl(str moduleName, d: (Declaration) `<Tags tags> <Visibility visibility> data <UserType user> <CommonKeywordParameters commonKeywordParameters> ;`) { 
    dtags = getTags(tags);
    adtName = "<user.name>";
    content = trim(dtags["doc"] ? "");
    return [dataInfo(moduleName, adtName, "data <user> <commonKeywordParameters>",
                                       d@\loc, getSynopsis(dtags, content), content)];
}

list[DeclarationInfo]  extractDecl(str moduleName, d: (Declaration) `<Tags tags> <Visibility visibility> data <UserType user> <CommonKeywordParameters commonKeywordParameters> = <{Variant "|"}+ variants> ;`) { 
    dtags = getTags(tags);
    adtName = "<user.name>";
    infoVariants = [ genVariant(moduleName, variant) | variant <- variants ];
    content = trim(dtags["doc"] ? "");
    return dataInfo(moduleName, adtName, "data <user> <commonKeywordParameters> <align(variants)>",
                                       d@\loc, getSynopsis(dtags, content), content) + infoVariants;
}

DeclarationInfo genVariant(str moduleName, v: (Variant) `<Name name>(<{TypeArg ","}* _> <KeywordFormals _>)`){
    signature = "<v>";
    return constructorInfo(moduleName, "<name>", "<v>", v@\loc);
}

list[DeclarationInfo]  extractDecl(str moduleName, d: (Declaration) `<FunctionDeclaration functionDeclaration>`) = [ extractFunDecl(moduleName, functionDeclaration) ];

// -- function declaration ------------------------------------------

DeclarationInfo extractFunDecl(str moduleName, fd: (FunctionDeclaration) `<Tags tags> <Visibility visibility> <Signature signature> ;`)   {
  return extractFunctionDeclaration(moduleName, fd);
}

DeclarationInfo extractFunDecl(str moduleName, fd: (FunctionDeclaration) `<Tags tags> <Visibility visibility> <Signature signature> = <Expression expression> ;`){
  return extractFunctionDeclaration(moduleName, fd);
}

DeclarationInfo extractFunDecl(str moduleName, fd: (FunctionDeclaration) `<Tags tags> <Visibility visibility> <Signature signature> = <Expression expression> when <{Expression ","}+ conditions>;`){
  return extractFunctionDeclaration(moduleName, fd); 
}

DeclarationInfo extractFunDecl(str moduleName, fd: (FunctionDeclaration) `<Tags tags>  <Visibility visibility> <Signature signature> <FunctionBody body>`){
  return extractFunctionDeclaration(moduleName, fd);
}

private DeclarationInfo extractFunctionDeclaration(str moduleName, FunctionDeclaration fd){
  fname = "<fd.signature.name>";
  
  signature =  "<fd.signature>";
  if(startsWith(signature, "java")){
    signature = signature[size("java")+1 .. ];
  }
   
  tags =  getTags(fd.tags);
  content = trim(tags["doc"] ? "");
  return functionInfo(moduleName, fname, signature, fd@\loc, getSynopsis(tags, content), content);
}

/********************************************************************/
/*      Get tags in a function declaration                          */
/********************************************************************/

str getSynopsis(map[str, str] tags, str docContents) {
    if ("doc" in tags) {
      s = trim(docContents);
      synopsis = ".Synopsis\n";
      if(startsWith(s, synopsis)){
          s = s[size(synopsis) ..];
          return trim(s[ .. findFirst(s, "\n")]);
      }
      return s [ .. findFirst(s, "\n")];
    }
    else if ("synopsis" in tags) {
      return trim(tags["synopsis"]);
    }
    else {
      return "";
    }
}

public map[str,str] getTags(Tags tags){
   m = ();
   for(tg <- tags.tags){
     str name = "<tg.name>";
     if(tg is \default){
        cont = "<tg.contents>"[1 .. -1];
        m[name] = cont;
     } else if (tg is empty)
        m[name] = "";
     else
        m[name] = "<tg.expression>"[1 .. -1];
   }
   return m;
}
module lang::rascal::tutor::Indexer

import util::Reflective;
import ValueIO;
import String;
import util::FileSystem;
import IO;

import lang::rascal::tutor::apidoc::DeclarationInfo;
import lang::rascal::tutor::apidoc::ExtractInfo;
import lang::rascal::tutor::Names;

rel[str, str] createConceptIndex(PathConfig pcfg) {
    ind = createConceptIndex(pcfg.srcs);

    // store index for later usage by depending documentation projects
    writeBinaryValueFile(pcfg.bin + "index.value", ind);

    // read indices from projects we depend on, if present
    ind += {readBinaryValueFile(#rel[str,str], inx) | l <- pcfg.libs, inx := l + "doc" + "index.value", exists(inx)};

    return ind;
}

rel[str, str] createConceptIndex(list[loc] srcs) 
  = {*createConceptIndex(src) | src <- srcs};

@synopsis{creates a lookup table for concepts nested in a folder}
rel[str, str] createConceptIndex(loc src)
  = // first we collect index entries for concept names, each file is one concept which
    // can be linked to in 6 different ways ranging from very short but likely inaccurate to
    // rather long, but guaranteed to be exact:
    { 
      // `((StrictSuperSetSet)) -> #Expressions-Values-Set-StrictSuperSet``
      <cf.file, fr>,

      // `((Set-StrictSuperSet)) -> #Expressions-Values-Set-StrictSuperSet``
      *{<"<f.parent.parent.file>-<cf.file>", fr> | f.parent.path != "/", f.parent.file == cf.file, f.parent != src},

      // `((Expressions-Values-Set-StrictSuperSet)) -> #Expressions-Values-Set-StrictSuperSet``
      *{<"<fr[1..]>", fr>},

      // `((Rascal:StrictSuperSet)) -> /Rascal.md#Expressions-Values-Set-StrictSuperSet``
      <"<capitalize(src.file)>:<capitalize(cf.file)>", "/<capitalize(src.file)>.md<fr>">,

      // `((Rascal:Set-StrictSuperSet)) -> /Rascal.md#Expressions-Values-Set-StrictSuperSet``
      *{<"<capitalize(src.file)>:<capitalize(f.parent.parent.file)>-<capitalize(cf.file)>", "/<src.file>.md<fr>"> | f.parent.path != "/", f.parent.file == cf.file},     

      // `((Rascal:Expressions-Values-Set-StrictSuperSet)) -> /Rascal.md#Expressions-Values-Set-StrictSuperSet``
      <"<capitalize(src.file)>:<fr[1..]>", fr>

    | loc f <- find(src, isConceptFile), fr := fragment(src, f), cf := f[extension=""]
    }
  + // Now follow the index entries for image files:
    { <"<f.parent.file>-<f.file>", "/assets/<md5>.<f.extension>">,
      <f.file, "/assets/<md5>.<f.extension>">,
      <"<capitalize(src.file)>:<f.file>", "/assets/<md5>.<f.extension>">
    |  loc f <- find(src, isImageFile), md5 := md5HashFile(f)
    }
  + // Here come the index entries for Rascal modules and declarations:
    {  // `((getDefaultPathConfig))` -> `#util-Reflective-getDefaultPathConfig`
      *{<"<item.kind>:<item.name>","<moduleFragment(item.moduleName)>-<item.name>">, <item.name, "<moduleFragment(item.moduleName)>-<item.name>" > | item.name?},
     
      // `((Library:getDefaultPathConfig))` -> `/Library.md#util-Reflective-getDefaultPathConfig`
      *{<"<capitalize(src.file)>:<item.name>", "/<capitalize(src.file)>.md/<moduleFragment(item.moduleName)>-<item.name>" >,
         <"<capitalize(src.file)>:<item.kind>:<item.name>", "/<capitalize(src.file)>.md/<moduleFragment(item.moduleName)>-<item.name>" > | item.name?},

      // `((util::Reflective::getDefaultPathConfig))` -> `#util-Reflective-getDefaultPathConfig`
      *{<"<item.moduleName><sep><item.name>", "<moduleFragment(item.moduleName)>-<item.name>" >,
        <"<item.kind>:<item.moduleName><sep><item.name>", "<moduleFragment(item.moduleName)>-<item.name>" > | item.name?, sep <- {"::", "-"}},

      // ((Library:util::Reflective::getDefaultPathConfig))` -> `#util-Reflective-getDefaultPathConfig`
      *{<"<capitalize(src.file)>:<item.moduleName><sep><item.name>", "/<capitalize(src.file)>.md/<moduleFragment(item.moduleName)>-<item.name>" >,
         <"<capitalize(src.file)>:<item.kind>:<item.moduleName><sep><item.name>", "/<capitalize(src.file)>.md/<moduleFragment(item.moduleName)>-<item.name>" > | item.name?, sep <- {"::", "-"}},

      // ((Set)) -> `#Set`
      *{<item.moduleName, "<moduleFragment(item.moduleName)>" >, <"module:<item.moduleName>", "<moduleFragment(item.moduleName)>" > | item is moduleInfo},

      // `((Library:Set))` -> `/Library.md#Set`
      *{<"<capitalize(src.file)>:<item.moduleName>", "/<capitalize(src.file)>.md/<moduleFragment(item.moduleName)>" >,
         <"<capitalize(src.file)>:module:<item.moduleName>", "/<capitalize(src.file)>.md/<moduleFragment(item.moduleName)>" > | item is moduleInfo}

      | loc f <- find(src, "rsc"), list[DeclarationInfo] inf := extractInfo(f), item <- inf
    }
    ;

private bool isConceptFile(loc f) = f.extension in {"md"};
private bool isRascalFile(loc f) = f.extension in {"rsc"};
private bool isImageFile(loc f) = f.extension in {"png", "jpg", "svg", "jpeg"};

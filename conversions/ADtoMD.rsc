@synopsis{Temporary utility conversions for evolving the tutor syntax from AsciiDoc to Docusaurus Markdown}
module lang::rascal::tutor::conversions::ADtoMD

import util::FileSystem;
import IO;
import String;

void ad2md(loc root) {
    for (f <- find(root, "md"))
      convertFile(f);
}

void convertFile(loc file) {
    println("converting: <file>");
    result=for (l <- readFileLines(file)) {
        append convertLine(l);
    }

    writeFileLines(file, result);
}

// link:/Libraries#Prelude-Map[map functions]
str convertLine(/<prefix:.*>link:\/<course:[A-Za-z0-9]+>#<concept:[A-Za-z0-9\-]+>\[<title:[^\]]*>\]<postfix:.*$>/) 
  = convertLine("<prefix>[<title>]((<trim(course)>:<trim(concept)>))<postfix>");

// link:/WhyRascal[Why Rascal]
str convertLine(/<prefix:.*>link:\/<course:[A-Za-z0-9]+>\[<title:[^\]]*>\]<postfix:.*$>/)
  = convertLine("<prefix>[<title>]((<trim(course)>))<postfix>");

// <<Hello>>
str convertLine(/<prefix:.*>\<\<<concept:[A-Za-z0-9\-]+>\>\><postfix:.*$>/)
  = convertLine("<prefix>((<trim(concept)>))<postfix>");

// [[Extraction-Workflow]]
// image::define-extraction.png[width=400,align=left,title="Extraction Workflow"]
str convertLine(/^<prefix:.*>image::<filename:[A-Za-z\-0-9]+>\.<ext:png|jpeg|jpg|svg>\[<properties:[^\]]*>\]<postfix:.*$>/)
  = convertLine("<prefix>![<extractTitle(properties)>]((<filename>.<ext>))<postfix>");

default str convertLine(str line) = line;

str extractTitle(/title=\"<t:[^\"]+>\"/) = t;
default str extractTitle(str x) = "";
package org.rascalmpl.library.lang.rascal.tutor;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.URI;
import java.net.URISyntaxException;

import org.rascalmpl.library.experiments.Compiler.Commands.CommandOptions;
import org.rascalmpl.library.experiments.Compiler.RVM.Interpreter.NoSuchRascalFunction;
import org.rascalmpl.help.HelpManager;
import org.rascalmpl.library.experiments.Compiler.RVM.Interpreter.ideservices.BasicIDEServices;
import org.rascalmpl.library.experiments.Compiler.RVM.Interpreter.ideservices.IDEServices;
import org.rascalmpl.library.util.PathConfig;

public class Tutor {
	
	public static void main(String[] args) throws IOException, NoSuchRascalFunction, URISyntaxException, InterruptedException {
	    CommandOptions cmdOpts = new CommandOptions("Tutor Server");
	    cmdOpts.pathConfigOptions()
	    .boolOption("help")
	    .help("Print help message for this command")
	    .noModuleArgument()
	    .handleArgs(args);
	 
	  PathConfig pcfg = new PathConfig(cmdOpts.getCommandLocsOption("src"), cmdOpts.getCommandLocsOption("lib"), cmdOpts.getCommandLocOption("bin"), cmdOpts.getCommandLocOption("boot"));
	  PrintWriter stderr = new PrintWriter(System.err);
	  IDEServices ideServices = new BasicIDEServices(stderr);
	  HelpManager hm = new HelpManager(pcfg, new PrintWriter(System.out), stderr, ideServices, false);
	  hm.refreshIndex();
	  ideServices.browse(new URI("http://localhost:" + hm.getPort() + "/TutorHome/index.html"));
	}
}

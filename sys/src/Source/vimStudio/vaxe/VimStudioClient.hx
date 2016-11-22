package vimStudio.vaxe;

import sys.io.File;
import haxe.io.Path;
import sys.net.Host;
import sys.net.Socket;
import sys.FileSystem;
import sys.io.Process;

import vimStudio.vaxe.HxSource;
import rn.dataTree.projectTree.*;

import rn.typext.hlp.FileSystemHelper;

using StringTools;
using rn.typext.ext.XmlExtender;

class VimStudioClient {
	static function echoRequest (request:Array<String>) : String
		return (new Process("neko", ["../../vim-studio/sys/VimStudioClient.n"].concat(request))).stdout.readAll().toString();
	
	public static function main () : Void {
		Sys.setCwd(Path.directory(FileSystem.fullPath(
			#if neko
				neko.vm.Module.local().name
			#elseif cpp
				Sys.executablePath()
			#end
		)));
		
		var args:Array<String> = Sys.args().map(function (arg:String) return arg.replace("\\ ", " ").trim());
		
		switch(args[0]) {
			case "vaxe":
				switch (args[1]) {
					case "rename_project":
						Sys.stdout().writeString(HxSource.setProjectName(args[2], args[3], args[4]) ? "1" : "0");
					case "is_valid_file":
						Sys.stdout().writeString(Path.extension(args[2]) == "hx" || FileSystem.isDirectory(args[2]) ? "1" : "0");
					case "check_source_file":
						Sys.stdout().writeString(HxSource.checkSource(args[2], FileSystem.isDirectory(args[3]) ? args[3] : Path.directory(args[3])) ? "1" : "0");
					case "delete_source":
						Sys.stdout().writeString(HxSource.deleteSource(args[2], args[3], args[4]) ? "1" : "0");
					case "add_source":
						Sys.stdout().writeString(
							HxSource.addSource(
								args[2],
								args[3],
								FileSystemHelper.getRelativePath(
									Path.directory(args[3]),
									args[6] == "1" ? echoRequest(["project", "get_path_by_index", args[2], args[4]]) :
										FileSystem.isDirectory(args[5]) ? args[5] :
											Path.directory(args[5])
								)
							) ? "1" : "0"
						);
					case "rename_source":
						Sys.stdout().writeString(HxSource.renameSource(args[2], args[3], args[4], args[5]) ? "1" : "0");
					case "update_sources":
						Sys.stdout().writeString(HxSource.updateSources(args[2], args[3]) ? "1" : "0");
					case "hxml_set_target":
						Sys.stdout().writeString(HxSource.setTarget(args[2], args[3]) ? "1" : "0");
					case "add_lime_source":
						var target:Array<String> = args[4].split(" ");
						Sys.stdout().writeString(
							HxSource.addSource(
								args[2],
								args[3],
								Path.join([
									HxSource.getOutDirectory(args[3], args[4]), target[0] + target[1].replace("-", ""),
									target[2].replace("-", ""), "haxe"
								])
							) ? "1" : "0"
						);
					case "make_hxml_by_xml":
						if (FileSystem.exists(args[3]) && Path.extension(args[3]) == "xml") {
							(new Process("lime", ["update", args[3]].concat(args[4].split(" "))));
							var instructions:Array<String> = (new Process("lime", ["display", args[3]].concat(args[4].split(" ")))).stdout.readAll().toString().split("\n");
							HxSource.updateInstruction(instructions, true, "-main ApplicationMain", -1, '-main ${ProjectTemplate.getClassName(args[2])}');
							File.saveContent(args[3] + ".hxml", instructions.join("\n"));
							Sys.stdout().writeString("1");
						}
						else
							Sys.stdout().writeString("0");
					default:
						Sys.stdout().writeString("0");
				}
			default:
				Sys.stdout().writeString(echoRequest(args));
		}
	}
}

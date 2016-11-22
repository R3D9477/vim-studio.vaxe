package vimStudio.vaxe;

import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.Process;

import rn.dataTree.flatTree.*;
import rn.dataTree.projectTree.*;

import rn.typext.hlp.FileSystemHelper;

using Lambda;
using StringTools;
using rn.typext.ext.XmlExtender;
using rn.typext.ext.StringExtender;

class HxSource {
	public static function checkSource (srcPath:String, projDirPath:String) : Bool {
		srcPath = Path.normalize(srcPath);
		
		if (srcPath == FileSystem.fullPath(srcPath))
			srcPath = Path.join([projDirPath, srcPath]);
		
		if (FileSystem.exists(srcPath))
			if (FileSystem.isDirectory(srcPath))
				return FileSystem.readDirectory(srcPath).find(function (file:String) return Path.extension(file) == "hx") != null;
		
		return false;
	}
	
	public static function getProjectType (hx_proj_path:String) : String
		switch(Path.extension(hx_proj_path)) {
			case "xml", "lime":
				return "lime";
			case "hxml":
				return "hxml";
			case "flow":
				return "flow";
			default:
				return "";
		}
	
	public static function hxmlIndexOf (hxml_content:Array<String>, hxml_instruction:String) : Int {
		for (i in 0...hxml_content.length)
			if (hxml_content[i].indexOf(hxml_instruction) >= 0)
				return i;
		
		return -1;
	}
	
	public static function getInstructionValue (hxml_content:Array<String>, hxml_instruction:String) : String {
		var instr_content:Array<String>;
		
		for (instruction in hxml_content)
			if ((instr_content = instruction.split(" ")).length > 1)
				if (instr_content[0].indexOf(hxml_instruction) >= 0)
					return instr_content[1];
		
		return "";
	}
	
	public static function updateInstruction (hxml_content:Array<String>, is_needed:Bool, hx_instruction:String, hx_insert_index:Int = -1, hx_new_instruction:String = "") : Bool {
		var result:Bool = false;
		var hxml_instr_index:Int;
		
		if ((hxml_instr_index = hxmlIndexOf(hxml_content, hx_instruction)) == -1 && is_needed && hx_insert_index >= 0) {
			hxml_content.insert(hx_insert_index, hx_new_instruction > "" ? hx_new_instruction : hx_instruction);
			result = true;
		}
		else if (hxml_instr_index > -1 && is_needed) {
			if (hx_new_instruction > "")
				hxml_content[hxml_instr_index] = hx_new_instruction;
			result = true;
		}
		else if (hxml_instr_index > -1 && !is_needed)
			while ((hxml_instr_index = hxmlIndexOf(hxml_content, hx_instruction)) != -1)
				hxml_content.splice(hxml_instr_index, 1);
		
		return result;
	}
	
	public static function setTarget (hx_proj_path:String, hx_target:String) : Bool {
		var xml_proj_path:String = Path.extension(hx_proj_path) == "xml" ? hx_proj_path : Path.withoutExtension(hx_proj_path);
		var hxml_proj_path:String = Path.extension(hx_proj_path) == "hxml" ? hx_proj_path : hx_proj_path + ".hxml";
		
		if (!FileSystem.exists(hxml_proj_path) && !FileSystem.exists(xml_proj_path))
			return false;
		
		var hxml_content:Array<String> = File.getContent(hxml_proj_path).split("\n");
		var hxml_insert_index:Int = hxmlIndexOf(hxml_content, "-main") + 1;
		
		//// SET TARGET OS
		
		// DESKTOP
		
		var is_linux:Bool = updateInstruction(hxml_content, (hx_target.indexOf("linux") > -1), "-D linux", hxml_insert_index);
		var is_mac:Bool = updateInstruction(hxml_content, (hx_target.indexOf("mac") > -1), "-D mac", hxml_insert_index);
		var is_windows:Bool = updateInstruction(hxml_content, (hx_target.indexOf("windows") > -1), "-D windows", hxml_insert_index);
		
		updateInstruction(hxml_content, (is_linux || is_mac || is_windows), "-D desktop", hxml_insert_index);
		
		// MOBILE
		
		var is_android:Bool = updateInstruction(hxml_content, (hx_target.indexOf("android") > -1), "-D android", hxml_insert_index);
		var is_blackberry:Bool = updateInstruction(hxml_content, (hx_target.indexOf("blackberry") > -1), "-D blackberry", hxml_insert_index);
		var is_ios:Bool = updateInstruction(hxml_content, (hx_target.indexOf("ios") > -1), "-D ios", hxml_insert_index);
		var is_webos:Bool = updateInstruction(hxml_content, (hx_target.indexOf("webos") > -1), "-D webos", hxml_insert_index);
		
		updateInstruction(hxml_content, (is_android || is_blackberry || is_ios || is_webos), "-D mobile", hxml_insert_index);
		
		updateInstruction(hxml_content, is_android, "-D android-9", hxml_insert_index);
		updateInstruction(hxml_content, is_ios, "-D iphone", hxml_insert_index);
		updateInstruction(hxml_content, is_webos, "-D HXCPP_RTLD_LAZY", hxml_insert_index);
		
		// WEB
		
		var is_flash = updateInstruction(hxml_content, (hx_target.indexOf("flash") > -1), "-D flash", hxml_insert_index);
		var is_html5 = updateInstruction(hxml_content, (hx_target.indexOf("html5") > -1), "-D html5", hxml_insert_index);
		
		updateInstruction(hxml_content, (is_flash || is_html5), "-D web", hxml_insert_index);
		
		updateInstruction(hxml_content, is_flash, "-swf-version 11.2", hxml_insert_index);
		updateInstruction(hxml_content, is_flash, "-swf-header 800:600:30:FFFFFF", hxml_insert_index);
		updateInstruction(hxml_content, is_html5, "-D html", hxml_insert_index);
		
		//// SET EXPORT DIR & TARGET INSTRUCTION
		
		var hxml_export_index:Int;
		var root_export_dir:String;
		
		if ((hxml_export_index = hxmlIndexOf(hxml_content, "-cp Export")) > -1) {
			if (["linux", "mac", "windows", "android", "ios", "blackberry", "webos", "flash", "html5"].find(function (target:String) {
				if (hxml_content[hxml_export_index].indexOf(target) > -1) {
					root_export_dir = hxml_content[hxml_export_index].split("-cp ")[1].split(target)[0].trim();
					return true;
				}
				
				return false;
			}) == null)
				root_export_dir = hxml_content[hxml_export_index];
		}
		else if (FileSystem.exists(xml_proj_path))
			root_export_dir = Xml.parse(File.getContent(xml_proj_path)).getByXpath("//project//app").get("path");
		else
			root_export_dir = "Export";
		
		var export_dir:String = Path.join([root_export_dir,
			// DEKSTOP
			is_linux ? "linux" : is_mac ? "mac" : is_windows ? "windows" :
			// MOBILE
			is_android ? "android" : is_ios ? "ios" : is_blackberry ? "blackberry" : is_webos ? "webos" :
			// WEB
			is_flash ? "flash" : is_html5 ? "html5" :
			// DEFAULT
			""
		]);
		
		if (hx_target.indexOf("-64") > -1)
			export_dir += "64";
		
		// DEKSTOP & MOBILE
		if (hx_target.indexOf("-cs") > -1)
			hx_target = "cs";
		else if (hx_target.indexOf("-neko") > -1)
			hx_target = "neko";
		else if (hx_target.indexOf("-cpp") > -1 || hx_target.indexOf("webos") > -1)
			hx_target = "cpp";
		// WEB
		else if (hx_target.indexOf("flash") > -1)
			hx_target = "flash";
		else if (hx_target.indexOf("html5") > -1)
			hx_target = "html5";
		
		var hxml_target_instruction;
		
		switch (hx_target) {
			// DESKTOP & MOBILE
			case "cs":
				hxml_target_instruction = "-cs " + export_dir;
				updateInstruction(hxml_content, true, "-cs", hxml_insert_index, hxml_target_instruction);
				
				export_dir = "-cp " + Path.join([export_dir, "cs", "src", "haxe"]);
			case "neko":
				hxml_target_instruction = "-neko " + Path.join([export_dir, "obj", hxml_content[hxmlIndexOf(hxml_content, "-main")].split("-main ")[1].trim() + ".n"]);
				updateInstruction(hxml_content, true, "-neko", hxml_insert_index, hxml_target_instruction);
				
				export_dir = "-cp " + Path.join([export_dir, "neko", "haxe"]);
			case "cpp":
				hxml_target_instruction = "-cpp " + Path.join([export_dir, "obj/"]);
				updateInstruction(hxml_content, true, "-cpp", hxml_insert_index, hxml_target_instruction);
				
				export_dir = "-cp " + Path.join([export_dir, "cpp", "haxe"]);
			// WEB
			case "flash":
				hxml_target_instruction = "-swf " + Path.join([export_dir, "bin", hxml_content[hxmlIndexOf(hxml_content, "-main")].split("-main ")[1].trim() + ".swf"]);
				updateInstruction(hxml_content, true, "-swf", hxml_insert_index, hxml_target_instruction);
				
				export_dir = "-cp " + Path.join([export_dir, "haxe"]);
			case "html5":
				hxml_target_instruction = "-js " + Path.join([export_dir, "bin", hxml_content[hxmlIndexOf(hxml_content, "-main")].split("-main ")[1].trim() + ".js"]);
				updateInstruction(hxml_content, true, "-js", hxml_insert_index, hxml_target_instruction);
				
				export_dir = "-cp " + Path.join([export_dir, "haxe"]);
			default:
				return false;
		}
		
		updateInstruction(hxml_content, true, "-cp " + root_export_dir, hxml_insert_index, export_dir);
		
		// ADDITIONAL INSTRUCTIONS
		
		updateInstruction(hxml_content, (hx_target == "cs"), "-cs");
		updateInstruction(hxml_content, (hx_target == "cpp"), "-cpp");
		updateInstruction(hxml_content, (hx_target == "neko"), "-neko");
		updateInstruction(hxml_content, (hx_target == "flash"), "-swf");
		updateInstruction(hxml_content, (hx_target == "html5"), "-js");
		
		if (hxmlIndexOf(hxml_content, "-D lime") > -1) {
			if (is_html5)
				updateInstruction(hxml_content, true, "-D lime-native", null, "-D lime-html5");
			else if (is_flash) {
				updateInstruction(hxml_content, false, "-D lime-native");
				updateInstruction(hxml_content, false, "-D lime-html5");
			}
			else
				updateInstruction(hxml_content, true, "-D lime-html5", null, "-D lime-native");
		}
		
		updateInstruction(hxml_content, (hx_target == "cs"), "-D haxe3", hxml_insert_index);
		updateInstruction(hxml_content, (hx_target == "cs"), "-D net-ver=40", hxml_insert_index);
		
		// SAVE CHANGES
		
		File.saveContent(hxml_proj_path, hxml_content.join("\n"));
		
		return true;
	}
	
	public static function deleteSource (vimStudio_path:String, xml_proj_path:String, file_path:String) : Bool {
		if (!FileSystem.exists(xml_proj_path))
			return false;
		
		var file_dir_path:String = FileSystem.isDirectory(file_path) ? file_path : Path.directory(file_path);
		var src_path:String = FileSystemHelper.getRelativePath(Path.directory(xml_proj_path), file_dir_path);
		
		var hx_doc:Xml = Xml.parse(File.getContent(xml_proj_path));
		var hx_src:Xml = hx_doc.getByXpath('//project/source[@path="' + src_path + '"]');
		
		if (hx_src != null) {
			hx_src.removeSelf();
			
			File.saveContent(xml_proj_path, hx_doc.toString());
		}
		
		File.saveContent(xml_proj_path + '.hxml', File.getContent(xml_proj_path + '.hxml').replace('\n-cp ' + src_path, ''));
		
		var hx_proj_path:String = Path.join([Path.directory(xml_proj_path), Path.withoutDirectory(Path.withExtension(vimStudio_path, 'hxproj'))]);
		
		hx_doc = Xml.parse(File.getContent(hx_proj_path));
		hx_src = hx_doc.getByXpath('//project/classpaths/class[@path="' + src_path + '"]');
		
		if (hx_src != null) {
			hx_src.removeSelf();
			
			File.saveContent(hx_proj_path, hx_doc.toString());
		}
		
		return true;
	}
	
	public static function addSource (vimStudio_path:String, xml_proj_path:String, src_path:String) : Bool {
		if (!FileSystem.exists(xml_proj_path))
			return false;
		
		var hx_doc:Xml = Xml.parse(File.getContent(xml_proj_path));
		
		if (hx_doc.getByXpath('//project/source[@path="' + src_path + '"]') == null) {
			var hx_src:Xml = Xml.createElement('source'); 
			hx_src.set("path", src_path);
			
			hx_doc.getByXpath('//project').addChild(hx_src);
			
			File.saveContent(xml_proj_path, hx_doc.toString());
		}
		
		var hxml_src_exists:Bool = false;
		
		for (i in File.getContent(xml_proj_path + '.hxml').split('\n')) {
			var instruction:Array<String> = i.trim().split(' ');
			
			if (instruction.length > 1 && instruction[0] == '-cp') {
				if (instruction[1] == src_path) {
					hxml_src_exists = true;
					break;
				}
			}
		}
		
		if (!hxml_src_exists)
			FileSystemHelper.appendFile(xml_proj_path + '.hxml', '\n-cp ' + src_path);
		
		var hx_proj_path:String = Path.join([Path.directory(xml_proj_path), Path.withoutDirectory(Path.withExtension(vimStudio_path, 'hxproj'))]);
		
		hx_doc = Xml.parse(File.getContent(hx_proj_path));
		
		if (hx_doc.getByXpath('//project/classpaths/class[@path="' + src_path + '"]') == null) {
			var hx_src:Xml = Xml.createElement('class'); 
			hx_src.set("path", src_path);
			
			hx_doc.getByXpath('//project/classpaths').addChild(hx_src);
			
			File.saveContent(hx_proj_path, hx_doc.toString());
		}
		
		return true;
	}
	
	public static function renameSource (vimStudio_path:String, xml_proj_path:String, src_path:String, new_name:String) : Bool {
		var new_src:String = Path.join([Path.directory(src_path), new_name]);
		
		if (!FileSystem.exists(new_src))
			return false;
		
		if (!FileSystem.isDirectory(new_src))
			return false;
		
		if (!FileSystem.exists(xml_proj_path))
			return false;
		
		if (!checkSource(new_src, FileSystem.fullPath(Path.directory(xml_proj_path))))
			return false;
		
		var projDir:String = FileSystemHelper.getRelativePath(Path.directory(xml_proj_path), src_path);
		
		src_path = src_path.replace(projDir, "");
		new_src = new_src.replace(projDir, "");
		
		var hx_doc:Xml = Xml.parse(File.getContent(xml_proj_path));
		var src_elem:Xml;
		
		if ((src_elem = hx_doc.getByXpath('//project/source[@path="' + src_path + '"]')) != null) {
			src_elem.set("path", new_src);
			File.saveContent(xml_proj_path, hx_doc.toString());
		}
		
		if (FileSystem.exists(xml_proj_path + '.hxml')) {
			var hxml_content:Array<String> = File.getContent(xml_proj_path + '.hxml').split('\n');
			
			for (i in 0...hxml_content.length) {
				var instruction:Array<String> = hxml_content[i].trim().split(' ');
				
				if (instruction.length > 1 && instruction[0] == '-cp')
					if (instruction[1] == src_path) {
						hxml_content[i] = '-cp ${new_src}';
						File.saveContent(xml_proj_path + ".hxml", hxml_content.join("\n"));
						break;
					}
			}
		}
		
		var hx_proj_path:String = Path.join([Path.directory(xml_proj_path), Path.withoutDirectory(Path.withExtension(vimStudio_path, 'hxproj'))]);
		
		if (FileSystem.exists(hx_proj_path)) {
			hx_doc = Xml.parse(File.getContent(hx_proj_path));
			
			if ((src_elem = hx_doc.getByXpath('//project/classpaths/class[@path="' + src_path + '"]')) == null) {
				src_elem.set("path", new_src);
				File.saveContent(hx_proj_path, hx_doc.toString());
			}
		}
		
		return true;
	}
	
	public static function updateSources (vimStudio_path:String, xml_proj_path:String) : Bool {
		if (!FileSystem.exists(xml_proj_path))
			return false;
		
		var projDirPath:String = FileSystem.fullPath(Path.directory(xml_proj_path));
		
		var cleanSrcHxml:String->Void = function (xmlPath:String) : Void {
			var changed:Bool = false;
			
			var hxml_doc:Array<String> = File.getContent(xmlPath + '.hxml').split('\n').filter(function (instruction:String) : Bool {
				instruction = instruction.trim();
			
				if (instruction.length > 0) {
					if (instruction.substring(0, 1) != '#') {
						var instructionarr:Array<String> = instruction.split(' ');
						
						if (instruction.length > 1 && instructionarr[0] == '-cp')
							if (!checkSource(instructionarr[1], projDirPath)) {
								changed = true;
								return false;
							}
					}
				}
				
				return true;
			});
			
			if (changed)
				File.saveContent(xmlPath + '.hxml', hxml_doc.join('\n'));
		}
		
		var cleanSrcXml:String->String->Void = function (xmlPath:String, xpath:String) : Void {
			var changed:Bool = false;
			
			var hx_doc:Xml = Xml.parse(File.getContent(xmlPath));
			
			for (hx_src in hx_doc.findByXpath(xpath)) {
				var src:String = Path.normalize(hx_src.get("path"));
				
				if (src == FileSystem.fullPath(src))
					src = Path.join([Path.directory(xmlPath), src]);
				
				if (!checkSource(hx_src.get("path"), projDirPath)) {
					hx_src.removeSelf();
					changed = true;
				}
			};
			
			if (changed)
				File.saveContent(xmlPath, hx_doc.toString());
		}
		
		cleanSrcHxml(xml_proj_path);
		cleanSrcXml(xml_proj_path, '//project/source');
		cleanSrcXml(Path.withExtension(xml_proj_path, 'hxproj'), '//project/classpaths/class');
		
		var ftree:FlatTree = new FlatTree();
		ftree.loadTreeFromFile(Path.withExtension(vimStudio_path, "tree"));
		
		var hxFiles:Array<String> = ftree.itemsList
			.map(function (item:FlatTreeItem) return cast(item, ProjectTreeItem).path)
			.filter(function (path:String) {
				if (Path.extension(path) == "hx")
					return FileSystemHelper.getRelativePath(path, Path.directory(xml_proj_path)).split("/")[0] != "Export";
				return false;
			});
		
		for (hxSource in hxFiles)
			addSource(vimStudio_path, xml_proj_path, hxSource);
		
		return true;
	}
	
	public static function setProjectName (vimStudio_oldPath:String, vimStudio_newPath:String, xml_proj_path:String) : Bool {
		xml_proj_path = xml_proj_path.replace(
			Path.addTrailingSlash(Path.withoutExtension(vimStudio_oldPath)),
			Path.addTrailingSlash(Path.withoutExtension(vimStudio_newPath))
		);
		
		if (!FileSystem.exists(vimStudio_newPath))
			return false;
		
		var projNewName:String = Path.withoutExtension(Path.withoutDirectory(vimStudio_newPath));
		
		if (FileSystem.exists(xml_proj_path)) {
			var hx_doc:Xml = Xml.parse(File.getContent(xml_proj_path));
			hx_doc.getByXpath('//project/meta').set("title", projNewName);
			hx_doc.getByXpath('//project/app').set("file", projNewName);
			File.saveContent(xml_proj_path, hx_doc.toString());
		}
		
		var projOldName:String = Path.withoutExtension(Path.withoutDirectory(vimStudio_oldPath));
		var hxproj_path:String = Path.join([Path.withoutExtension(vimStudio_newPath), projOldName + ".hxproj"]);
		
		if (!FileSystem.exists(hxproj_path))
			hxproj_path = Path.join([Path.withoutExtension(vimStudio_newPath), projOldName.toTitleCase() + ".hxproj"]);
		
		if (FileSystem.exists(hxproj_path))
			FileSystem.rename(
				hxproj_path,
				Path.join([
					Path.directory(hxproj_path),
					Path.withExtension(Path.withoutDirectory(vimStudio_newPath), "hxproj")
				])
			);
		
		return true;
	}
	
	public static function getMainClass (hx_proj_path:String) : String
		return switch (Path.extension(hx_proj_path)) {
			case "xml": Xml.parse(File.getContent(hx_proj_path)).getByXpath("//project/app").get("main");
			case "hxml": getInstructionValue(File.getContent(hx_proj_path).split("\n"), "-main");
			default: "";
		}
	
	public static function getOutDirectory (hx_proj_path:String, target:String) : String
		return switch (Path.extension(hx_proj_path)) {
			case "xml": Xml.parse(File.getContent(hx_proj_path)).getByXpath("//project/app").get("path");
			case "hxml": getInstructionValue(File.getContent(hx_proj_path).split("\n"), target.split(" ")[2]);
			default: "";
		}
}

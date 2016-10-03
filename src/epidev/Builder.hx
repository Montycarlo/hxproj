package epidev;

import sys.FileSystem;
import sys.io.Process;
import sys.io.File;
import epidev.cli.PrintHelper.*;

@:final class Builder{

	private var props:Properties;

	public function new(p:Properties){
		this.props = p;
	}

	public function buildCmd():Array<String>{
		var cmds = ['-main', props.main];

		cmds.push('-${props.target}');
		if(TargetDetails.targetRequiresDir(props)){
			var outdir = '${props.out_dir}/${props.target}';
			if(!FileSystem.exists(outdir))
				FileSystem.createDirectory(outdir);
			cmds.push(outdir);
		}else{
			var dir = props.out_dir == "" ? "" : '${props.out_dir}/';
			cmds.push('$dir${props.out_bin}');
		}

		for(cp in props.sources) 
			cmds = cmds.concat(["-cp", cp]);

		for(lib in Reflect.fields(props.libraries_haxe)){
			var r = ':${Reflect.field(props.libraries_haxe, lib)}';
			if(r == ":*") r = "";
			cmds = cmds.concat(["-lib", '$lib$r']);
		}

		for(flag in props.flags) 
			cmds = cmds.concat(["-D", flag]);
		
		return cmds;
	}

	public function echoBuildCmd():Void{
		println_(buildCmd().join(" "));
	}

	public function build():Void{
		var cmd:Array<String> = buildCmd();

		printGood_("haxe "+cmd.join(" "));
		var p = new Process("haxe", cmd);
		var code = p.exitCode();
		if(code != 0){
			printErr('Compile error $code');
			println_("\t"+p.stderr.readAll().toString());
			return;
		}
		
		if(TargetDetails.targetRequiresDir(props))
			FileSystem.rename(TargetDetails.getDefaultOutput(props), props.out_bin);

		if(props.prepend != null && props.prepend.length > 0){
			var ppc = File.getContent(props.prepend);
			var cc = File.getContent(props.out_bin);
			File.saveContent(props.out_bin, ppc+cc);
		}
	}

}

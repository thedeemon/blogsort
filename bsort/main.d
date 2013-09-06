module main;
//import std.stdio, scans, dfl.application, dfl.messagebox, std.process, std.c.windows.com;
import dfl.application, bsform;

void main(string[] argv)
{
	//CoInitialize(null);
	Application.enableVisualStyles();
	//Application.autoCollect = false;
	auto frm = new MainForm();
	Application.run(frm);
}

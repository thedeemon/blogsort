import dfl.all;

class Help: dfl.form.Form
{
	// Do not modify or move this block of variables.
	//~Entice Designer variables begin here.
	dfl.textbox.TextBox tbxHelp;
	dfl.button.Button btnSite;
	dfl.label.Label label1;
	dfl.label.Label label2;
	//~Entice Designer variables end here.
	
	this()
	{
		initializeHelp();
		//@  Other Help initialization code here.
	}
	
	private void initializeHelp()
	{
		// Do not manually modify this function.
		//~Entice Designer 0.8.5.02 code begins here.
		//~DFL Form
		text = "Help";
		clientSize = dfl.all.Size(616, 522);
		//~DFL dfl.textbox.TextBox=tbxHelp
		tbxHelp = new dfl.textbox.TextBox();
		tbxHelp.name = "tbxHelp";
		tbxHelp.bounds = dfl.all.Rect(8, 32, 600, 440);
		tbxHelp.parent = this;
		tbxHelp.multiline = true;
		tbxHelp.readOnly = true;
		tbxHelp.scrollBars = dfl.all.ScrollBars.VERTICAL;
		//~DFL dfl.button.Button=btnSite
		btnSite = new dfl.button.Button();
		btnSite.name = "btnSite";
		btnSite.text = "www.infognition.com";
		btnSite.bounds = dfl.all.Rect(296, 488, 200, 24);
		btnSite.parent = this;
		//~DFL dfl.label.Label=label1
		label1 = new dfl.label.Label();
		label1.name = "label1";
		label1.text = "(C) 2012-2013 Infognition Co. Ltd.";
		label1.textAlign = dfl.all.ContentAlignment.MIDDLE_LEFT;
		label1.bounds = dfl.all.Rect(16, 488, 256, 24);
		label1.parent = this;
		//~DFL dfl.label.Label=label2
		label2 = new dfl.label.Label();
		label2.name = "label2";
		label2.text = "About BlogSort";
		label2.textAlign = dfl.all.ContentAlignment.MIDDLE_CENTER;
		label2.bounds = dfl.all.Rect(184, 0, 252, 23);
		label2.parent = this;
		//~Entice Designer 0.8.5.02 code ends here.

		tbxHelp.text = import("readme.txt");
		btnSite.click ~= &OnSite;
		this.activated ~= (Form frm, EventArgs args) => btnSite.focus();
	}

	void OnSite(Control sender, EventArgs ea)
	{
		//	HINSTANCE ShellExecuteA(HWND hwnd, LPCSTR lpOperation, LPCSTR lpFile, LPCSTR lpParameters, LPCSTR lpDirectory, INT nShowCmd);
		import dfl.internal.winapi;
		ShellExecuteA(null, null, "http://www.infognition.com/", null, null, 5);
	}
}


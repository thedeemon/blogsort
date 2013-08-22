module bsform;
import dfl.all, std.string, std.file, std.c.windows.windows, std.conv, jpg, imageprocessor, std.algorithm, std.array, std.math;
version(verbose) import std.stdio;

class FileItem
{
	this(string fname)
	{
		fullname = fname;
		auto i = fname.lastIndexOf('\\');
		name = fname[i+1..$];
	}

	override string toString() const
	{
		return name;
	}

	string fullname, name;
}

class MyPictureBox : PictureBox {
	void BecomeOpaque()
	{
		setStyle(ControlStyles.OPAQUE, true);
	}
}


class MainForm : dfl.form.Form
{
	// Do not modify or move this block of variables.
	//~Entice Designer variables begin here.
	dfl.button.Button btnBrowse;
	dfl.button.Button btnSave;
	dfl.button.Button btnZoom;
	dfl.textbox.TextBox txtOutFile;
	dfl.label.Label label1;
	dfl.label.Label label2;
	dfl.textbox.TextBox txtWidth;
	dfl.label.Label label3;
	dfl.textbox.TextBox txtHeight;
	dfl.listbox.ListBox lbxFiles;
	dfl.label.Label label4;
	dfl.button.Button btnTurnLeft;
	dfl.button.Button btnTurnRight;
	dfl.button.Button btnUndoAll;
	dfl.button.Button btnHorizonLineup;
	dfl.button.Button btnCrop;
	dfl.button.Button btnAuto;
	dfl.button.Button btnUndo;
	dfl.button.Button btnHelp;
	//~Entice Designer variables end here.
	MyPictureBox picBox;

	this()
	{		
		imgProc = new ImageProcessor(&OnGotThumb);
		initializeMainForm();				
	}	
	
	private void initializeMainForm()
	{
		// Do not manually modify this function.
		//~Entice Designer 0.8.5.02 code begins here.
		//~DFL Form
		text = "blogsort";
		clientSize = dfl.all.Size(1300, 720);
		//~DFL dfl.button.Button=btnBrowse
		btnBrowse = new dfl.button.Button();
		btnBrowse.name = "btnBrowse";
		btnBrowse.text = "Browse";
		btnBrowse.bounds = dfl.all.Rect(8, 8, 64, 24);
		btnBrowse.parent = this;
		//~DFL dfl.button.Button=btnSave
		btnSave = new dfl.button.Button();
		btnSave.name = "btnSave";
		btnSave.text = "Save";
		btnSave.bounds = dfl.all.Rect(408, 8, 64, 24);
		btnSave.parent = this;
		//~DFL dfl.button.Button=btnZoom
		btnZoom = new dfl.button.Button();
		btnZoom.name = "btnZoom";
		btnZoom.text = "Zoom";
		btnZoom.bounds = dfl.all.Rect(486, 8, 64, 24);
		btnZoom.parent = this;
		//~DFL dfl.textbox.TextBox=txtOutFile
		txtOutFile = new dfl.textbox.TextBox();
		txtOutFile.name = "txtOutFile";
		txtOutFile.text = "c:\\temp\\out01.jpg";
		txtOutFile.bounds = dfl.all.Rect(120, 8, 280, 24);
		txtOutFile.parent = this;
		//~DFL dfl.label.Label=label1
		label1 = new dfl.label.Label();
		label1.name = "label1";
		label1.text = "Out:";
		label1.textAlign = dfl.all.ContentAlignment.MIDDLE_RIGHT;
		label1.bounds = dfl.all.Rect(80, 8, 36, 24);
		label1.parent = this;
		//~DFL dfl.label.Label=label2
		label2 = new dfl.label.Label();
		label2.name = "label2";
		label2.text = "max size:";
		label2.textAlign = dfl.all.ContentAlignment.MIDDLE_RIGHT;
		label2.bounds = dfl.all.Rect(1076, 8, 60, 24);
		label2.parent = this;
		//~DFL dfl.textbox.TextBox=txtWidth
		txtWidth = new dfl.textbox.TextBox();
		txtWidth.name = "txtWidth";
		txtWidth.text = "1200";
		txtWidth.textAlign = dfl.all.HorizontalAlignment.CENTER;
		txtWidth.bounds = dfl.all.Rect(1148, 8, 40, 24);
		txtWidth.parent = this;
		//~DFL dfl.label.Label=label3
		label3 = new dfl.label.Label();
		label3.name = "label3";
		label3.text = "x";
		label3.textAlign = dfl.all.ContentAlignment.MIDDLE_CENTER;
		label3.bounds = dfl.all.Rect(1196, 8, 12, 24);
		label3.parent = this;
		//~DFL dfl.textbox.TextBox=txtHeight
		txtHeight = new dfl.textbox.TextBox();
		txtHeight.name = "txtHeight";
		txtHeight.text = "900";
		txtHeight.textAlign = dfl.all.HorizontalAlignment.CENTER;
		txtHeight.bounds = dfl.all.Rect(1212, 8, 40, 24);
		txtHeight.parent = this;
		//~DFL dfl.listbox.ListBox=lbxFiles
		lbxFiles = new dfl.listbox.ListBox();
		lbxFiles.name = "lbxFiles";
		lbxFiles.bounds = dfl.all.Rect(8, 40, 182, 654);
		lbxFiles.parent = this;
		//~DFL dfl.label.Label=label4
		label4 = new dfl.label.Label();
		label4.name = "label4";
		label4.text = "rotate:";
		label4.textAlign = dfl.all.ContentAlignment.MIDDLE_RIGHT;
		label4.bounds = dfl.all.Rect(560, 8, 44, 24);
		label4.parent = this;
		//~DFL dfl.button.Button=btnTurnLeft
		btnTurnLeft = new dfl.button.Button();
		btnTurnLeft.name = "btnTurnLeft";
		btnTurnLeft.text = "L";
		btnTurnLeft.bounds = dfl.all.Rect(608, 8, 27, 24);
		btnTurnLeft.parent = this;
		//~DFL dfl.button.Button=btnTurnRight
		btnTurnRight = new dfl.button.Button();
		btnTurnRight.name = "btnTurnRight";
		btnTurnRight.text = "R";
		btnTurnRight.bounds = dfl.all.Rect(640, 8, 27, 24);
		btnTurnRight.parent = this;
		//~DFL dfl.button.Button=btnUndoAll
		btnUndoAll = new dfl.button.Button();
		btnUndoAll.name = "btnUndoAll";
		btnUndoAll.text = "Undo All";
		btnUndoAll.bounds = dfl.all.Rect(984, 8, 56, 24);
		btnUndoAll.parent = this;
		//~DFL dfl.button.Button=btnHorizonLineup
		btnHorizonLineup = new dfl.button.Button();
		btnHorizonLineup.name = "btnHorizonLineup";
		btnHorizonLineup.text = "Horizon";
		btnHorizonLineup.bounds = dfl.all.Rect(688, 8, 48, 24);
		btnHorizonLineup.parent = this;
		//~DFL dfl.button.Button=btnCrop
		btnCrop = new dfl.button.Button();
		btnCrop.name = "btnCrop";
		btnCrop.text = "Crop";
		btnCrop.bounds = dfl.all.Rect(744, 8, 48, 24);
		btnCrop.parent = this;
		//~DFL dfl.button.Button=btnAuto
		btnAuto = new dfl.button.Button();
		btnAuto.name = "btnAuto";
		btnAuto.text = "AutoLevel";
		btnAuto.bounds = dfl.all.Rect(800, 8, 64, 24);
		btnAuto.parent = this;
		//~DFL dfl.button.Button=btnUndo
		btnUndo = new dfl.button.Button();
		btnUndo.name = "btnUndo";
		btnUndo.text = "Undo";
		btnUndo.bounds = dfl.all.Rect(920, 8, 48, 24);
		btnUndo.parent = this;
		//~DFL dfl.button.Button=btnHelp
		btnHelp = new dfl.button.Button();
		btnHelp.name = "btnHelp";
		btnHelp.text = "?";
		btnHelp.bounds = dfl.all.Rect(1264, 8, 24, 24);
		btnHelp.parent = this;
		//~Entice Designer 0.8.5.02 code ends here.

		picBox = new MyPictureBox();
		picBox.name = "picBox";
		picBox.sizeMode = dfl.all.PictureBoxSizeMode.STRETCH_IMAGE;
		picBox.bounds = dfl.all.Rect(196, 40, 1100, 670);
		picBox.parent = this;

		btnBrowse.click ~= &OnBrowse;
		btnSave.click ~= &OnSave;
		btnZoom.click ~= &OnZoom;
		btnTurnLeft.click ~= &OnTurnLeft;
		btnTurnRight.click ~= &OnTurnRight;
		picBox.sizeMode = PictureBoxSizeMode.STRETCH_IMAGE;
		lbxFiles.drawMode = DrawMode.OWNER_DRAW_FIXED;
		lbxFiles.drawItem ~= &DrawItem;
		lbxFiles.itemHeight = 130;
		lbxFiles.sorted = false;
		lbxFiles.selectedValueChanged ~= &OnSelChanged;
		//txtWidth.keyPress ~= &OnOutSizeChange;
		//txtHeight.keyPress ~= &OnOutSizeChange;
		txtWidth.lostFocus ~= &OnOutSizeChange;
		txtHeight.lostFocus ~= &OnOutSizeChange;
		picBox.mouseDown ~= &OnMouseDown;
		picBox.mouseMove ~= &OnMouseMove;
		picBox.mouseUp ~= &OnMouseUp;
		picBox.mouseLeave ~= &OnMouseUp;
		picBox.paint ~= &PaintMarks;
		this.closed ~= &OnClose;
		btnUndoAll.click ~= &OnUndoAll;
		btnUndo.click ~= &OnUndo;
		btnHorizonLineup.click ~= &LineUpHorizon;
		btnCrop.click ~= &OnCrop;
		btnAuto.click ~= &OnAutoLevels;
		btnHelp.click ~= &OnHelp;
		this.resize ~= &OnResize;

		Control[] cs = [lbxFiles, this, picBox, btnUndoAll, btnHorizonLineup, btnSave, btnZoom, btnBrowse, btnCrop];
		foreach(c; cs) c.keyPress ~= &OnKey;

		toolTip = new ToolTip;
		toolTip.setToolTip(btnSave, "Save current image (G)");
		toolTip.setToolTip(btnTurnLeft, "Turn 90° left (L)");
		toolTip.setToolTip(btnTurnRight, "Turn 90° right (R)");
		toolTip.setToolTip(btnUndoAll, "Re-read the file");
		toolTip.setToolTip(btnUndo, "Undo last operation");
		toolTip.setToolTip(btnHorizonLineup, "Rotate the image to make marks on one horizontal line (H)");
		toolTip.setToolTip(btnZoom, "Switch between 100% fit and 1:1 scales (Z)");
		toolTip.setToolTip(btnCrop, "Crop (C)");
		toolTip.setToolTip(btnAuto, "AutoLevels (A)");
		toolTip.setToolTip(btnHelp, "Help / About");
		LoadSettings();
		ClearMarks();
	}

private:
	void LoadSettings()
	{
		try {
			subkey = Registry.currentUser.createSubKey("Software\\blogsort");
			auto path = cast(RegistryValueSz) subkey.getValue("path", new RegistryValueSz("c:\\temp\\"));
			txtOutFile.text = path.value ~ "pic01.jpg";

			auto mx = cast( RegistryValueDword) subkey.getValue("maxX", new  RegistryValueDword(1200));
			auto my = cast( RegistryValueDword) subkey.getValue("maxY", new  RegistryValueDword(900));
			ImageProcessor.maxOutX = mx.value;
			ImageProcessor.maxOutY = my.value;
			txtWidth.text  = to!string(mx.value);
			txtHeight.text = to!string(my.value);
		} catch(Exception ex) {
			version(verbose) writeln("registry error: ", ex);
		}		
	}

	void OnBrowse(Control sender, EventArgs ea)
	{
		auto ofd = new OpenFileDialog;
		ofd.title = "Open Image";
		ofd.filter = "All Image Files|*.bmp;*.ico;*.gif;*.jpg;*.jpeg|Bitmap Files|*.bmp|Icon Files|*.ico|JPEG Files|*.jpg;*.jpeg|All Files|*.*";
		imgProc.Start();
		if(DialogResult.OK == ofd.showDialog())
		{
			auto i = ofd.fileName.lastIndexOf('\\');
			bool[string] picext;
			foreach(ext; ["jpg", "bmp", "gif"]) picext[ext] = true;
			auto files = array(dirEntries(ofd.fileName[0..i], SpanMode.shallow)
								.filter!(name => name.isFile && name[$-3..$].toLower() in picext));
			auto sorted = files.sort();
			auto triple = sorted.trisect(ofd.fileName);
			string prevFile = triple[0].empty ? null : triple[0][$-1];
			string nextFile = triple[2].empty ? null : triple[2][0];

			lbxFiles.beginUpdate();
			lbxFiles.items.clear();
			foreach(name; files) 				
					lbxFiles.items.add(new FileItem(name));			
			lbxFiles.endUpdate();
			auto stamp = imgProc.GetTimeStamp(ofd.fileName);
			foreach(idx; 0..lbxFiles.items.length) {
				FileItem it = cast(FileItem)lbxFiles.items[idx];
				if (it.fullname == ofd.fileName) {
					lbxFiles.selectedIndex = idx;
					this.text = "blogsort " ~ it.name ~ " " ~ stamp;
					break;
				}
			}
			ShowImage( imgProc.FileSelected(prevFile, ofd.fileName, nextFile) );
		}
		lbxFiles.focus();
	}

	void OnSelChanged(ListControl lc, EventArgs ea)
	{
		int i = lbxFiles.selectedIndex;
		if (i < 0) return;
		auto n = lbxFiles.items.length;
		auto it = cast(FileItem) lbxFiles.items[i];
		auto prev = i > 0 ? cast(FileItem) lbxFiles.items[i-1] : null;
		auto next = i < n - 1 ? cast(FileItem) lbxFiles.items[i+1] : null;
		string prevFile = prev ? prev.fullname : null;
		string nextFile = next ? next.fullname : null;
		ShowImage( imgProc.FileSelected(prevFile, it.fullname, nextFile) );
		this.text = "blogsort " ~ it.name ~ " " ~ imgProc.GetTimeStamp(it.fullname);
		int top = lbxFiles.topIndex;
		int vn = lbxFiles.bounds.height / 130;
		if (i > 0 && i == top) lbxFiles.topIndex = top - 1;
		else
		if (i >= top + vn-1 && top + vn < n) lbxFiles.topIndex = top + 1;
	}

	void ShowImage(Image img)
	{
		if (img is null) {
			picBox.image = null;
			return;
		}
		int w0 = img.width, h0 = img.height, w, h, SX=bounds.width-200, SY=bounds.height-80;
		LimitSize(w0, h0, SX, SY, w, h);
		picBox.BecomeOpaque();
		picBox.image = img;
		picBox.bounds = dfl.all.Rect(196+SX/2-w/2, 40+SY/2-h/2, w, h);		
		picBox.invalidate(true);
	}

	string nextName(string fname) pure
	{
		auto dot = fname.lastIndexOf('.');
		return succ(fname[0..dot]) ~ ".jpg";
	}

	void OnSave(Control sender, EventArgs ea)
	{
		scope(exit) lbxFiles.focus();
		string fname = txtOutFile.text, orgname;
		if (imgProc.current is null) return; // nothing to save		
		if (imgProc.curFile in saved) {
			string msg = "This picture was already saved as " ~ saved[imgProc.curFile] ~ ". Save it as " ~ fname ~ " too?";
			if (msgBox(msg, "Possible duplicate", MsgBoxButtons.YES_NO, MsgBoxIcon.WARNING)==DialogResult.NO) return;
		}
		if (fname.exists) {
			if (msgBox("File " ~ fname ~ " exists. Overwrite?", "Warning", MsgBoxButtons.YES_NO, MsgBoxIcon.WARNING)==DialogResult.NO) {
				while(fname.exists) 
					fname = nextName(fname);
				txtOutFile.text = fname;
				return;
			}
		}
		if (imgProc.SaveCurrent(fname, orgname)) {
			saved[orgname] = fname;			
			txtOutFile.text = nextName(fname);
			lbxFiles.invalidate(true);
		} else
			msgBox("save failed, sorry");				
	}

	void DrawItem(Object sender, DrawItemEventArgs ea)
	{
		ea.drawBackground();

		FileItem it = cast(FileItem)lbxFiles.items[ea.index];
		Bitmap bmp = imgProc.GetThumb(it.fullname);
		if (bmp) {
			int w = bmp.width, h = bmp.height;
			bmp.draw(ea.graphics, Point(ea.bounds.x + 80-w/2, ea.bounds.y + 65-h/2));
		}

		if (it.fullname in saved) {
			scope Pen pen = new Pen(Color.fromRgb(0xFF00), 2);
			ea.graphics.drawRectangle(pen, Rect(ea.bounds.x + 2, ea.bounds.y + 2, ea.bounds.width - 4, ea.bounds.height-4));
		}

		ea.graphics.drawText(lbxFiles.items[ea.index].toString(), ea.font, ea.foreColor,
							 Rect(ea.bounds.x + 10, ea.bounds.y + 10, ea.bounds.width - 10, 20));
		ea.drawFocusRectangle();
	};

	void OnClose(Form f, EventArgs ea)
	{
		imgProc.Stop();
		auto bs = txtOutFile.text.lastIndexOf('\\');
		if (bs < 0 || subkey is null) return;
		subkey.setValue("path", new RegistryValueSz(txtOutFile.text[0..bs+1]));
		subkey.setValue("maxX", new RegistryValueDword(ImageProcessor.maxOutX));
		subkey.setValue("maxY", new RegistryValueDword(ImageProcessor.maxOutY));
		subkey.close();
	}

	void OnGotThumb(string fname)
	{
		int vn = lbxFiles.bounds.height / 130;
		foreach(i; 0..lbxFiles.items.length) {
			auto it = cast(FileItem) lbxFiles.items[i];
			if (it.fullname == fname) {
				int di = i - lbxFiles.topIndex;
				if (di >= 0 && di < vn)
					lbxFiles.invalidate(true);
				return;
			}
		}		
	}

	void OnKey(Control c, KeyPressEventArgs k)
	{
		switch(k.keyChar()) {
			case 'g': OnSave(null, null); break;
			case 'l': OnTurnLeft(null, null); break;
			case 'r': OnTurnRight(null, null); break;
			case 'z': OnZoom(null, null); break;
			case 'h': LineUpHorizon(null, null); break;
			case 'c': OnCrop(null, null); break;
			case 'a': OnAutoLevels(null, null); break;
			case '+': ChangeGamma(0.0625); break;
			case '-': ChangeGamma(-0.0625); break;
			default : 
		}		
		if (k.keyCode == Keys.ESCAPE) OnClearMarks(null, null);
		if (c is lbxFiles) k.handled = true;
	}

	void OnTurnLeft(Control sender, EventArgs ea)
	{
		if (imgProc.TurnLeft())  ShowImage(imgProc.current);
		ClearMarks();
		lbxFiles.focus();
	}

	void OnTurnRight(Control sender, EventArgs ea)
	{
		if (imgProc.TurnRight())  ShowImage(imgProc.current);
		ClearMarks();
		lbxFiles.focus();
	}

	void OnOutSizeChange(Control c, EventArgs k)
	{
		try { 
			int w = to!int(txtWidth.text);
			int h = to!int(txtHeight.text);
			version(verbose) writeln("new target size: ",w, "x",h);
			if (w > 0 && h > 0) 
				if (imgProc.ChangeOutSize(w,h))
					ShowImage(imgProc.current);
		} catch(ConvException ex) { }
	}

	void OnZoom(Control sender, EventArgs ea)
	{
		if (picBox.sizeMode == PictureBoxSizeMode.STRETCH_IMAGE)
			picBox.sizeMode = PictureBoxSizeMode.CENTER_IMAGE;
		else
			picBox.sizeMode = PictureBoxSizeMode.STRETCH_IMAGE;
		lbxFiles.focus();
	}

	void OnUndo(Control sender, EventArgs ea)
	{
		if (imgProc.Undo())  ShowImage(imgProc.current);
		lbxFiles.focus();
	}

	void OnUndoAll(Control sender, EventArgs ea)
	{
		if (imgProc.UndoAll())  ShowImage(imgProc.current);
		lbxFiles.focus();
	}

	void OnMouseDown(Control c, MouseEventArgs ma)
	{
		marking = true;
		OnMouseMove(c, ma);
	}

	void OnMouseMove(Control c, MouseEventArgs ma)
	{
		if (!marking) return;
		switch(ma.button) {
			case MouseButtons.RIGHT: SetMark(ma.x, ma.y); break;
			case MouseButtons.LEFT: SetCropMark(ma.x, ma.y); break;
			default:
		}
	}

	void OnMouseUp(Control c, MouseEventArgs ma)
	{
		marking = false;
	}

	void PaintMarks(Control c, PaintEventArgs pa)
	{			
		scope pen = new Pen(Color.fromRgb(0xff));
		foreach(m; horMarks) 
			if (m.x > 0 || m.y > 0) {
				pa.graphics.drawLine(pen, m.x - 10, m.y, m.x + 10, m.y);
				pa.graphics.drawLine(pen, m.x, m.y - 10, m.x, m.y + 10);
			}
		scope yellow = new Pen(Color.fromRgb(0xFFFF));
		if (cropMarks[0].x > cropMarks[1].x) {
			auto m = cropMarks[0];
			cropMarks[0] = cropMarks[1];
			cropMarks[1] = m;
		}
		if (cropMarks[1].x < 0) return;
		if (cropMarks[0].x >= 0 && cropMarks[1].x >= 0) {
			Vec dv = cropMarks[0] - cropMarks[1];
			pa.graphics.drawRectangle(yellow, min(cropMarks[0].x, cropMarks[1].x), min(cropMarks[0].y, cropMarks[1].y),
									  abs(dv.x), abs(dv.y));

		} else { // only one mark present
			auto m = cropMarks[1];
			pa.graphics.drawLine(yellow, m.x - 10, m.y, m.x + 10, m.y);
			pa.graphics.drawLine(yellow, m.x, m.y - 10, m.x, m.y + 10);
		}
	}

	void SetMark(int x, int y)
	{
		int dist(Vec p) { return p.x==0 && p.y==0 ? 0 : (p.x - x)^^2 + (p.y - y)^^2; }
		int i = 0;
		if (dist(horMarks[1]) < dist(horMarks[0])) i = 1;
		horMarks[i] = Vec(x, y);
		picBox.invalidate();
	}

	void SetCropMark(int x, int y)
	{
		int dist(Vec p) { return p.x < 0 ? 0 : (p.x - x)^^2 + (p.y - y)^^2; }
		int i = 0;
		if (dist(cropMarks[1]) < dist(cropMarks[0])) i = 1;
		cropMarks[i] = Vec(x, y);
		picBox.invalidate();
	}

	void OnClearMarks(Control sender, EventArgs ea)
	{
		ClearMarks();
		picBox.invalidate();
	}

	void ClearMarks()
	{
		foreach(ref m; horMarks) { m.x = 0; m.y = 0; }
		foreach(ref m; cropMarks) { m.x = -1; m.y = -1; }
	}

	void LineUpHorizon(Control sender, EventArgs ea)
	{
		scope(exit) lbxFiles.focus();
		foreach(m; horMarks) if (m.x==0 && m.y==0) return;
		if (horMarks[0].x == horMarks[1].x || horMarks[0].y == horMarks[1].y) return;
		int i = 0;
		if (horMarks[1].x < horMarks[0].x) i = 1;
		int dx = horMarks[i ^ 1].x - horMarks[i].x;
		int dy = horMarks[i ^ 1].y - horMarks[i].y;
		double angle = std.math.atan2(cast(double)dy, cast(double)dx);
		if (imgProc.FineRotation(angle)) { 
			ClearMarks();
			ShowImage(imgProc.current);
		}
	}

	void OnCrop(Control sender, EventArgs ea)
	{
		scope(exit) lbxFiles.focus();
		if (picBox.image is null) return;
		foreach(m; cropMarks) if (m.x < 0) return;
		int x0 = min(cropMarks[0].x, cropMarks[1].x);
		int y0 = min(cropMarks[0].y, cropMarks[1].y);
		int x1 = max(cropMarks[0].x, cropMarks[1].x);
		int y1 = max(cropMarks[0].y, cropMarks[1].y);
		int w = picBox.image.width, h = picBox.image.height;
		double ix0, iy0, ix1, iy1;		
		if (picBox.sizeMode == PictureBoxSizeMode.STRETCH_IMAGE) { //fit
			ix0 = cast(double) x0 / picBox.bounds.width;
			iy0 = cast(double) y0 / picBox.bounds.height;
			ix1 = cast(double) x1 / picBox.bounds.width;
			iy1 = cast(double) y1 / picBox.bounds.height;
		} else { //1:1
			ix0 = cast(double) (w/2 - (picBox.bounds.width/2 - x0)) / w;
			iy0 = cast(double) (h/2 - (picBox.bounds.height/2 - y0)) / h;
			ix1 = cast(double) (w/2 - (picBox.bounds.width/2 - x1)) / w;
			iy1 = cast(double) (h/2 - (picBox.bounds.height/2 - y1)) / h;
		}
		ClearMarks();
		ShowImage( imgProc.CropCurrent(ix0, iy0, ix1, iy1) );
	}

	void OnAutoLevels(Control sender, EventArgs ea)
	{		
		if (imgProc.AutoLevels())  ShowImage(imgProc.current);
		lbxFiles.focus();
	}

	void ChangeGamma(double delta)
	{
		if (imgProc.ChangeGamma(delta)) ShowImage(imgProc.current);
		lbxFiles.focus();
	}

	void OnResize(Control,EventArgs)
	{
		version(verbose) writeln("Resized: ", bounds);		
		if (picBox.image is null) return;
		auto img = picBox.image;
		int w0 = img.width, h0 = img.height, w, h, SX=bounds.width-200, SY=bounds.height-80;
		LimitSize(w0, h0, SX, SY, w, h);
		picBox.bounds = dfl.all.Rect(196+SX/2-w/2, 40+SY/2-h/2, w, h);

		int n = SY / 130;
		int n0 = lbxFiles.bounds.height / 130;
		if (n != n0) {
			lbxFiles.bounds = dfl.all.Rect(8, 40, 182, n*130+2);
		}		
	}

	void OnHelp(Control sender, EventArgs ea)
	{
		import help;
		auto frm = new Help();
		frm.showDialog();
		lbxFiles.focus();
	}

	ImageProcessor imgProc;
	string[string] saved;
	Vec[2] horMarks;
	ToolTip toolTip;
	RegistryKey subkey;
	Vec[2] cropMarks;
	bool marking = false;
}

/*
	Generated by Entice Designer
	Entice Designer written by Christopher E. Miller
	www.dprogramming.com/entice.php
*/

import dfl.all, std.string, std.file, std.c.windows.windows, std.conv, jpg, imageprocessor, std.algorithm, std.array;
version(verbose) import std.stdio;
version(rotatest) import std.math;

class FileItem
{
	this(string fname)
	{
		fullname = fname;
		auto i = fname.lastIndexOf('\\');
		name = fname[i+1..$];
	}

	string toString() const
	{
		return name;
	}

	string fullname, name;
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
	dfl.picturebox.PictureBox picBox;
	dfl.label.Label label4;
	dfl.button.Button btnTurnLeft;
	dfl.button.Button btnTurnRight;
	dfl.label.Label label5;
	dfl.button.Button btnHorizonClear;
	dfl.button.Button btnHorizonLineup;
	//~Entice Designer variables end here.
	
	this()
	{		
		imgProc = new ImageProcessor(&onGotThumb);
		initializeMyForm();		
		//@  Other MyForm initialization code here.		
	}	
	
	private void initializeMyForm()
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
		btnSave.bounds = dfl.all.Rect(428, 8, 64, 24);
		btnSave.parent = this;
		//~DFL dfl.button.Button=btnZoom
		btnZoom = new dfl.button.Button();
		btnZoom.name = "btnZoom";
		btnZoom.text = "Zoom";
		btnZoom.bounds = dfl.all.Rect(528, 8, 64, 24);
		btnZoom.parent = this;
		//~DFL dfl.textbox.TextBox=txtOutFile
		txtOutFile = new dfl.textbox.TextBox();
		txtOutFile.name = "txtOutFile";
		txtOutFile.text = "e:\\zhzm\\out01.jpg";
		txtOutFile.bounds = dfl.all.Rect(128, 8, 280, 24);
		txtOutFile.parent = this;
		//~DFL dfl.label.Label=label1
		label1 = new dfl.label.Label();
		label1.name = "label1";
		label1.text = "Out:";
		label1.textAlign = dfl.all.ContentAlignment.MIDDLE_RIGHT;
		label1.bounds = dfl.all.Rect(88, 8, 36, 23);
		label1.parent = this;
		//~DFL dfl.label.Label=label2
		label2 = new dfl.label.Label();
		label2.name = "label2";
		label2.text = "max size:";
		label2.textAlign = dfl.all.ContentAlignment.MIDDLE_RIGHT;
		label2.bounds = dfl.all.Rect(1040, 8, 52, 23);
		label2.parent = this;
		//~DFL dfl.textbox.TextBox=txtWidth
		txtWidth = new dfl.textbox.TextBox();
		txtWidth.name = "txtWidth";
		txtWidth.text = "1200";
		txtWidth.textAlign = dfl.all.HorizontalAlignment.CENTER;
		txtWidth.bounds = dfl.all.Rect(1096, 8, 48, 23);
		txtWidth.parent = this;
		//~DFL dfl.label.Label=label3
		label3 = new dfl.label.Label();
		label3.name = "label3";
		label3.text = "x";
		label3.textAlign = dfl.all.ContentAlignment.MIDDLE_CENTER;
		label3.bounds = dfl.all.Rect(1152, 8, 12, 23);
		label3.parent = this;
		//~DFL dfl.textbox.TextBox=txtHeight
		txtHeight = new dfl.textbox.TextBox();
		txtHeight.name = "txtHeight";
		txtHeight.text = "900";
		txtHeight.textAlign = dfl.all.HorizontalAlignment.CENTER;
		txtHeight.bounds = dfl.all.Rect(1168, 8, 48, 23);
		txtHeight.parent = this;
		//~DFL dfl.listbox.ListBox=lbxFiles
		lbxFiles = new dfl.listbox.ListBox();
		lbxFiles.name = "lbxFiles";
		lbxFiles.bounds = dfl.all.Rect(8, 40, 182, 654);
		lbxFiles.parent = this;
		//~DFL dfl.picturebox.PictureBox=picBox
		picBox = new dfl.picturebox.PictureBox();
		picBox.name = "picBox";
		picBox.sizeMode = dfl.all.PictureBoxSizeMode.STRETCH_IMAGE;
		picBox.bounds = dfl.all.Rect(196, 40, 1100, 670);
		picBox.parent = this;
		//~DFL dfl.label.Label=label4
		label4 = new dfl.label.Label();
		label4.name = "label4";
		label4.text = "rotate:";
		label4.textAlign = dfl.all.ContentAlignment.MIDDLE_RIGHT;
		label4.bounds = dfl.all.Rect(616, 8, 44, 23);
		label4.parent = this;
		//~DFL dfl.button.Button=btnTurnLeft
		btnTurnLeft = new dfl.button.Button();
		btnTurnLeft.name = "btnTurnLeft";
		btnTurnLeft.text = "L";
		btnTurnLeft.bounds = dfl.all.Rect(664, 8, 27, 24);
		btnTurnLeft.parent = this;
		//~DFL dfl.button.Button=btnTurnRight
		btnTurnRight = new dfl.button.Button();
		btnTurnRight.name = "btnTurnRight";
		btnTurnRight.text = "R";
		btnTurnRight.bounds = dfl.all.Rect(696, 8, 27, 24);
		btnTurnRight.parent = this;
		//~DFL dfl.label.Label=label5
		label5 = new dfl.label.Label();
		label5.name = "label5";
		label5.text = "horizon:";
		label5.textAlign = dfl.all.ContentAlignment.MIDDLE_RIGHT;
		label5.bounds = dfl.all.Rect(744, 8, 44, 23);
		label5.parent = this;
		//~DFL dfl.button.Button=btnHorizonClear
		btnHorizonClear = new dfl.button.Button();
		btnHorizonClear.name = "btnHorizonClear";
		btnHorizonClear.text = "Clear";
		btnHorizonClear.bounds = dfl.all.Rect(800, 8, 48, 24);
		btnHorizonClear.parent = this;
		//~DFL dfl.button.Button=btnHorizonLineup
		btnHorizonLineup = new dfl.button.Button();
		btnHorizonLineup.name = "btnHorizonLineup";
		btnHorizonLineup.text = "Line up";
		btnHorizonLineup.bounds = dfl.all.Rect(856, 8, 48, 24);
		btnHorizonLineup.parent = this;
		//~Entice Designer 0.8.5.02 code ends here.

		btnBrowse.click ~= &onBrowse;
		btnSave.click ~= &onSave;
		btnZoom.click ~= &onZoom;
		btnTurnLeft.click ~= &onTurnLeft;
		btnTurnRight.click ~= &onTurnRight;
		picBox.sizeMode = PictureBoxSizeMode.STRETCH_IMAGE;
		lbxFiles.drawMode = DrawMode.OWNER_DRAW_FIXED;
		lbxFiles.drawItem ~= &drawItem;
		lbxFiles.itemHeight = 130;
		lbxFiles.sorted = false;
		lbxFiles.selectedValueChanged ~= &OnSelChanged;
		lbxFiles.keyPress ~= &OnKey;
		this.keyPress ~= &OnKey;
		picBox.keyPress ~= &OnKey;
		txtWidth.keyPress ~= &OnOutSizeChange;
		txtHeight.keyPress ~= &OnOutSizeChange;
		txtWidth.lostFocus ~= &OnOutSizeChange;
		txtHeight.lostFocus ~= &OnOutSizeChange;
		picBox.mouseDown ~= &onMouseDown;
		picBox.mouseUp ~= &onMouseUp;
		picBox.mouseLeave ~= &onMouseUp;
		picBox.mouseMove ~= &onMouseMove;
		picBox.paint ~= &paintMarks;
		this.closed ~= &OnClose;
		btnHorizonClear.click ~= &clearMarks;
		btnHorizonLineup.click ~= &lineUpHorizon;
		this.resize ~= &OnResize;

		toolTip = new ToolTip;
		toolTip.setToolTip(btnSave, "Save current image (key: g)");
		toolTip.setToolTip(btnTurnLeft, "Turn 90° left (key: l)");
		toolTip.setToolTip(btnTurnRight, "Turn 90° right (key: r)");
		toolTip.setToolTip(btnHorizonClear, "Clear the horizon marks");
		toolTip.setToolTip(btnHorizonLineup, "Rotate the image to make marks on one horizontal line");
		toolTip.setToolTip(btnZoom, "Switch between 100% fit and 1:1 scales (key: z)");
	}

private:
	void onBrowse(Control sender, EventArgs ea)
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
			foreach(idx; 0..lbxFiles.items.length) {
				FileItem it = cast(FileItem)lbxFiles.items[idx];
				if (it.fullname == ofd.fileName) {
					lbxFiles.selectedIndex = idx;
					break;
				}
			}
			showImage( imgProc.FileSelected(prevFile, ofd.fileName, nextFile) );
		}
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
		showImage( imgProc.FileSelected(prevFile, it.fullname, nextFile) );
		int top = lbxFiles.topIndex;
		if (i > 0 && i == top) lbxFiles.topIndex = top - 1;
		else
		if (i >= top + 4 && top + 5 < n) lbxFiles.topIndex = top + 1;
	}

	void showImage(Image img)
	{
		if (img is null) {
			picBox.image = null;
			return;
		}
		int w0 = img.width, h0 = img.height, w, h, SX=bounds.width-200, SY=bounds.height-80;
		limitSize(w0, h0, SX, SY, w, h);
		picBox.image = img;
		picBox.bounds = dfl.all.Rect(196+SX/2-w/2, 40+SY/2-h/2, w, h);		
		picBox.invalidate(true);
	}

	string nextName(string fname)
	{
		auto dot = fname.lastIndexOf('.');
		return succ(fname[0..dot]) ~ ".jpg";
	}

	void onSave(Control sender, EventArgs ea)
	{
		string fname = txtOutFile.text, orgname;
		if (fname.exists) {
			if (msgBox("File " ~ fname ~ " exists. Overwrite?", "Warning", MsgBoxButtons.YES_NO, MsgBoxIcon.WARNING)==DialogResult.NO) {
				while(fname.exists) 
					fname = nextName(fname);
				txtOutFile.text = fname;
				return;
			}
		}
		if (imgProc.SaveCurrent(fname, orgname)) {
			saved[orgname] = true;			
			txtOutFile.text = nextName(fname);
			lbxFiles.invalidate(true);
		} else
			msgBox("save failed, sorry");		
	}

	void drawItem(Object sender, DrawItemEventArgs ea)
	{
		ea.drawBackground();
		//ea.graphics.drawIcon(f.icon, ea.bounds.x + 2, ea.bounds.y + 2);

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
	}

	void onGotThumb(string fname)
	{
		foreach(i; 0..lbxFiles.items.length) {
			auto it = cast(FileItem) lbxFiles.items[i];
			if (it.fullname == fname) {
				int di = i - lbxFiles.topIndex;
				if (di >= 0 && di < 6)
					lbxFiles.invalidate(true);
				return;
			}
		}		
	}

	void OnKey(Control c, KeyPressEventArgs k)
	{
		switch(k.keyChar()) {
			case 'g': onSave(null, null); break;
			case 'l': onTurnLeft(null, null); break;
			case 'r': onTurnRight(null, null); break;
			case 'z': onZoom(null, null); break;
			default : 
		}		
	}

	void onTurnLeft(Control sender, EventArgs ea)
	{
		if (imgProc.TurnLeft())  showImage(imgProc.current);
	}

	void onTurnRight(Control sender, EventArgs ea)
	{
		if (imgProc.TurnRight())  showImage(imgProc.current);
	}

	void OnOutSizeChange(Control c, EventArgs k)
	{
		try { 
			int w = to!int(txtWidth.text);
			int h = to!int(txtHeight.text);
			version(verbose) writeln("new target size: ",w, "x",h);
			if (w > 0 && h > 0) {
				ImageProcessor.maxOutX = w;
				ImageProcessor.maxOutY = h;
			}
		} catch(ConvException ex) { }
	}

	void onZoom(Control sender, EventArgs ea)
	{
		if (picBox.sizeMode == PictureBoxSizeMode.STRETCH_IMAGE)
			picBox.sizeMode = PictureBoxSizeMode.CENTER_IMAGE;
		else
			picBox.sizeMode = PictureBoxSizeMode.STRETCH_IMAGE;
	}

	void onMouseDown(Control c, MouseEventArgs ma)
	{
		if (ma.button != MouseButtons.RIGHT) return;		
		setMark(ma.x, ma.y);
	}

	void onMouseUp(Control c, MouseEventArgs ma)
	{		
	}

	void onMouseMove(Control c, MouseEventArgs ma)
	{
		if (ma.button != MouseButtons.RIGHT) return;		
		setMark(ma.x, ma.y);
	}

	void paintMarks(Control c, PaintEventArgs pa)
	{	
		version(rotatest) { if (rotatesting) {
			real a = (cast(real)ang) * 3.14159265 / 180;
			int w2 = 250, h2 = 150; // /2		
			real x = w2 * cos(a) - h2 * sin(a);
			real y = w2 * sin(a) + h2 * cos(a);
			int ix = cast(int)x;
			int iy = cast(int)y;
			int cx = 550, cy = 350;
			real x2 = -w2 * cos(a) - h2 * sin(a);
			real y2 = -w2 * sin(a) + h2 * cos(a);
			int ix2 = cast(int)x2;
			int iy2 = cast(int)y2;

			scope Pen pen = new Pen(Color.fromRgb(0));
			scope Pen red = new Pen(Color.fromRgb(0xff));
			pa.graphics.drawLine(pen, cx + ix, cy + iy, cx + ix2, cy + iy2);
			pa.graphics.drawLine(pen, cx + ix2, cy + iy2, cx - ix, cy - iy);
			pa.graphics.drawLine(pen, cx - ix, cy - iy, cx - ix2, cy - iy2);
			pa.graphics.drawLine(pen, cx - ix2, cy - iy2, cx + ix, cy + iy);

			if (iy == iy2) return; // not rotated
			int maxarea = 0, bx=0, by=0;
			Vec[4] rc = [Vec(ix,iy), Vec(ix2,iy2), Vec(-ix,-iy), Vec(-ix2, -iy2)];
			foreach(pt; 0..100) {
				int px = pt * ix / 100 + (100-pt) * ix2 / 100;
				int py = pt * iy / 100 + (100-pt) * iy2 / 100;
				bool inside = insideRect(Vec(px, -py), rc);
				if (inside) pa.graphics.drawEllipse(red, cx+px, cy+py, 3, 3);
				int area = abs(py) * abs(px);
				if (inside && area > maxarea) {
					maxarea = area;
					bx = px; by = py;
				}
			}
			pa.graphics.drawLine(red, cx + bx, cy + by, cx - bx, cy + by);
			pa.graphics.drawLine(red, cx - bx, cy + by, cx - bx, cy - by);
			pa.graphics.drawLine(red, cx - bx, cy - by, cx + bx, cy - by);
			pa.graphics.drawLine(red, cx + bx, cy - by, cx + bx, cy + by);
			/*Vec[4] rc = [Vec(ix,iy), Vec(ix2,iy2), Vec(-ix,-iy), Vec(-ix2, -iy2)];
			foreach(n; 0..1500) {
				Vec v = Vec(std.random.uniform(-300, 300), std.random.uniform(-300, 300));
				if (insideRect(v, rc))
					pa.graphics.drawEllipse(red, cx+v.x, cy+v.y, 3, 3);
			}*/

			return;
		}
		}
		scope Pen pen = new Pen(Color.fromRgb(0xff));
		foreach(m; horMarks) 
			if (m.x > 0 || m.y > 0) {
				pa.graphics.drawLine(pen, m.x - 10, m.y, m.x + 10, m.y);
				pa.graphics.drawLine(pen, m.x, m.y - 10, m.x, m.y + 10);
			}
	}

	void setMark(int x, int y)
	{
		int dist(Point p) { return p.x==0 && p.y==0 ? 0 : (p.x - x)^^2 + (p.y - y)^^2; }
		int i = 0;
		if (dist(horMarks[1]) < dist(horMarks[0])) i = 1;
		horMarks[i] = Point(x, y);
		picBox.invalidate();
	}

	void clearMarks(Control sender, EventArgs ea)
	{
		version(rotatest) {
			if (rotatesting) {
				rtimer.stop();
				rotatesting = false;
				return;
			}
		}

		foreach(ref m; horMarks) {
			m.x = 0; m.y = 0;
		}
		picBox.invalidate();
	}

	void lineUpHorizon(Control sender, EventArgs ea)
	{
		foreach(m; horMarks) if (m.x==0 && m.y==0) return;
		if (horMarks[0].x == horMarks[1].x || horMarks[0].y == horMarks[1].y) return;
		int i = 0;
		if (horMarks[1].x < horMarks[0].x) i = 1;
		int dx = horMarks[i ^ 1].x - horMarks[i].x;
		int dy = horMarks[i ^ 1].y - horMarks[i].y;
		double angle = std.math.atan2(cast(double)dy, cast(double)dx);
		version(verbose) writeln("angle=", angle*180/3.14159265);
		version(rotatest) StartRotation();
		else {
			if (imgProc.FineRotation(angle)) { 
				foreach(ref m; horMarks) { m.x = 0; m.y = 0; }
				showImage(imgProc.current);
			}
		}
	}

	void OnResize(Control,EventArgs)
	{
		version(verbose) writeln("Resized: ", bounds);		
		if (picBox.image is null) return;
		auto img = picBox.image;
		int w0 = img.width, h0 = img.height, w, h, SX=bounds.width-200, SY=bounds.height-80;
		limitSize(w0, h0, SX, SY, w, h);
		picBox.bounds = dfl.all.Rect(196+SX/2-w/2, 40+SY/2-h/2, w, h);

		int n = SY / 130;
		int n0 = lbxFiles.bounds.height / 130;
		if (n != n0) {
			lbxFiles.bounds = dfl.all.Rect(8, 40, 182, n*130+2);
		}		
	}

	version(rotatest) {
	void StartRotation()
	{
		ang = 0; rotatesting = true;
		rtimer = new Timer;
		rtimer.interval = 100;
		rtimer.tick ~= &RotaTest;
		rtimer.start();
	}

	void RotaTest(Timer sender, EventArgs ea)
	{
		ang += 5;
		picBox.invalidate();

	}
	}

	ImageProcessor imgProc;
	bool[string] saved;
	Point[2] horMarks;
	ToolTip toolTip;

	version(rotatest) {
	Timer rtimer; // for experiments 
	int ang = 0;
	bool rotatesting = false;
	}
}

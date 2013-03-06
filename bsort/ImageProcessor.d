module imageprocessor;
import dfl.all, std.c.windows.windows, dfl.internal.winapi, std.concurrency, std.range, core.time, std.algorithm;
import std.typecons, jpg, config, std.math, std.file, core.thread;
version(verbose) import std.stdio; 

class CachedImage
{
	int last_req;
	string fname;
	this(int req, string filename) { last_req = req; fname = filename; }
	abstract void dispose();
	abstract void dispose() shared;
}

class Pic : CachedImage
{
	Bitmap bmp;
	double[] cropped;

	this(string filename, Bitmap bitmap, int req = 0)
	{
		super(req, filename);  bmp = bitmap; 
	}

	void ReplaceBmp(Bitmap b)
	{
		if (bmp) delete bmp;
		bmp = b;
		cropped = [];
	}
	override void dispose() { if (bmp) delete bmp; }
	override void dispose() shared { if (bmp) delete bmp; }
}

class CachedPicture : CachedImage
{
	Picture pic;

	this(string filename, Picture pict, int req = 0)
	{
		super(req, filename); pic = pict;
	}

	override void dispose() { if (pic) pic.dispose(); }
	override void dispose() shared { if (pic) { auto p = cast(Picture) pic; p.dispose(); } }
}

// messages
struct HaveWork { } 
struct Exit {}
struct ThumbCreated { string fname; shared Bitmap bmp; int req; }
struct Prepared     { string fname; shared Bitmap bmp; }

enum Priority {
	Immediate = 0, Soon = 1, Visible = 2, Background = 3
}

class Job 
{ 
	Priority prio; 
	string fname;
	this(Priority p, string filename) { prio = p; fname = filename; }
}

class JGetThumb : Job 
{
	int req;
	this(string filename, int req_no) { super(Priority.Visible, filename); req = req_no; }
	override string toString() const { return "GetThumb " ~ fname; }
}

class JPrepare : Job //read and resize to blogsize
{
	int angle;
	double fangle;
	this(string filename, int rotation, double frot) { super(Priority.Soon, filename); angle = rotation; fangle = frot; }
	override string toString() const { return "Prepare " ~ fname; }
}

synchronized class LabourDept
{
	void PostJob(shared Job job)
	{
		auto j = cast(Job)job;
		version(verbose) writeln("PostJob: ", j);
		foreach(existing; jobs[job.prio]) {
			if (existing.fname == job.fname) {
				auto jgt = cast(JGetThumb) job;
				auto egt = cast(JGetThumb) existing;
				if (jgt && egt)
					egt.req = max(egt.req, jgt.req);
				version(verbose) writeln("already in queue");
				return;
			}
		}
		jobs[job.prio] ~= job;
		if (job.prio == Priority.Visible && jobs[job.prio].length > config.maxThumbJobs) {
			jobs[job.prio] = jobs[job.prio][$-config.maxThumbJobs..$];
		}
	}

	shared(Job) GetJob()
	{
		foreach(p; 0..4) {
			if (jobs[p].length > 0) {
				auto job = jobs[p][0];
				jobs[p] = jobs[p][1..$];
				auto j = cast(Job)job;
				version(verbose) writeln("run job ", j);
				return job;
			}
		}
		return null;
	}

	static shared LabourDept dept;
	static shared bool quit = false;

private:
	Job[][4] jobs; //4 priorities	
}

void LimitSize(int w0, int h0, int maxX, int maxY, ref int w, ref int h)
{
	w = min(maxX, w0);
	h = h0 * w / w0;
	if (h > maxY) {
		h = maxY;
		w = w0 * h / h0;
	}
}

Bitmap RedPic(int w = 160, int h = 120)
{
	HBITMAP hbm = CreateCompatibleBitmap(Graphics.getScreen().handle, w, h);
	int[] data;
	data.length = w*h;
	data[0..$] = 0xFF0000; 
	SetBitmapBits(hbm, data.length*4, data.ptr);
	delete data;		
	return new Bitmap(hbm, true);
}

class PictureCache
{
	CachedPicture[string] pic_cache;
	bool[string] loading_pics;
	int pic_req_no = 0;	

	Picture Get(string fname) shared
	{
		pic_req_no++;
		if (fname in pic_cache) {
			auto p = pic_cache[fname];
			p.last_req = pic_req_no;
			return cast(Picture) p.pic;
		}
		return null;
	}

	Picture WaitIfLoading(string fname) shared
	{
		version(verbose) writeln("wait for loading ", fname);
		while(true) {
			bool loading = false;
			synchronized(this) {
				auto loaded = fname in pic_cache;
				if (loaded) {
					version(verbose) writeln("wait ended ok for ", fname);
					return cast(Picture) pic_cache[fname].pic;
				}
				loading = !!(fname in loading_pics);
			}
			if (loading) {
				if (LabourDept.quit) return null;
				version(verbose) writeln("sleeping waiting ", fname);
				Thread.sleep( dur!("msecs")(77) );
				continue;
			}
			return null; // not found at all
		}		
	}

	synchronized void Loaded(string name, Picture pic) 
	{
		loading_pics.remove(name);
		pic_req_no++;				
		pic_cache[name] = new shared(CachedPicture)(name, pic, pic_req_no);
		if (pic_cache.length > config.pictureCacheSize) {
			auto tbs = pic_cache.byKey().map!((string name) => tuple(name, pic_cache[name]));
			auto mp = tbs.minCount!((a,b) => a[1].last_req < b[1].last_req)[0];
			auto cp = cast(CachedPicture) mp[1];
			cp.dispose();
			pic_cache.remove(mp[0]);
		}
	}
}

shared PictureCache picCache;

Picture ReadPicture(string fname)
{
	bool already_loading = false;
	synchronized(picCache) {
		auto pic = picCache.Get(fname);
		if (pic) return pic;
		already_loading = !!(fname in picCache.loading_pics);
	}
	if (already_loading) {
		auto pic = picCache.WaitIfLoading(fname);
		if (pic) return pic;
	}
	// fname not in cache and not loading. do it now
	synchronized(picCache) { picCache.loading_pics[fname] = true; }
	int tries = 3;
	while(tries > 0) {
		try {
			version(verbose) { 
				writeln("reading picture ", fname);
				auto t0 = core.time.TickDuration.currSystemTick;
			}
			auto p = new Picture(fname);
			version(verbose) { 
				auto dt = core.time.TickDuration.currSystemTick - t0;
				writefln("picture %s read in %s ms.", fname, dt.msecs);
			}
			picCache.Loaded(fname, p);
			return p;
		} catch (DflException ex) { //failed
			Thread.sleep( dur!("msecs")(100) );
			tries++;			
		}
	}
	return null; //completely failed to read
}

Bitmap ReadBitmap(string fname)
{
	auto pic = cast(Picture) ReadPicture(fname);
	if (pic) {		
		return pic.toBitmap();
	} else
		return RedPic(100,100);
}

shared(Bitmap) ResizeToThumb(Picture pic)
{
	Graphics g = Graphics.getScreen();
	HDC memdc = CreateCompatibleDC(g.handle);
	if (memdc is null) return null;
	scope(exit) DeleteDC(memdc);
	int w0 = pic.width, h0 = pic.height, w,h;
	LimitSize(w0, h0, 160, 120, w, h);
	HBITMAP hbm = CreateCompatibleBitmap(g.handle, w, h);
	if (hbm is null) return null;
	HGDIOBJ oldbm = SelectObject(memdc, hbm);
	pic.drawStretched(memdc, Rect(0,0, w,h));
	if(oldbm)
		SelectObject(memdc, oldbm);		
	return new shared(Bitmap)(hbm, true);
}

shared(Bitmap) ResizeForBlog(Bitmap orgbmp)
{
	int h0 = orgbmp.height, w0 = orgbmp.width, w,h;
	ubyte[] org;
	int orgsz = w0 * h0 * 4;
	org.length = orgsz;	
	scope(exit) delete org;	
	auto res = GetBitmapBits(orgbmp.handle, org.length, org.ptr);
	assert(res==orgsz);

	LimitSize(w0, h0, ImageProcessor.maxOutX, ImageProcessor.maxOutY, w, h);
	if (w>=w0 && h>=h0) 
		return cast(shared(Bitmap))orgbmp;

	version(verbose) auto tt0 = core.time.TickDuration.currSystemTick;
	ubyte[] data;
	data.length = w * h * 4;
	int[3][] row;
	row.length = w;
	real h0h = cast(real) h0 / h, w0w = cast(real) w0 / w, t0, t1;
	int[] sh0, sh1;
	int[] aisx0, aisx1;
	aisx0.length = w; aisx1.length = w; sh0.length = w; sh1.length = w;
	immutable eps = 1.0 / 256;
	immutable int kx = cast(int)(256 / w0w + 0.5), ky = cast(int) (256 / h0h + 0.5);
	foreach(x; 0..w) {
		real sx0 = x * w0w, sx1 = (x+1) * w0w;
		aisx0[x] = cast(int) sx0;
		aisx1[x] = cast(int) sx1;
		sh0[x] = cast(int) ((1.0 - modf(sx0, t0)) / w0w * 256 + 0.5);
		int kxarea = (aisx1[x] - aisx0[x] - 1)*kx;
		if ((sh0[x] + kxarea) > 256)
			sh0[x] = 256 - kxarea;
		sh1[x] = 256 - sh0[x] - kxarea;
		assert(sh0[x] >= 0);
		assert(kxarea >= 0);
		assert(sh1[x] >= 0);
		assert(sh0[x] + kxarea + sh1[x] == 256);
	}
	aisx1[$-1] = aisx0[$-1];
	foreach(y; 0..h) {		
		/*int sy = y * h0 / h;	//nearest neighbor
		foreach(x; 0..w) {
			int sx = x * w0 / w;
			int si = (sy * w0 + sx) * 4;
			data[di..di+3] = org[si..si+3];
			di += 4;
		}*/
		real sy0 = h0h * y, sy1 = h0h * (y+1);
		int isy0 = cast(int) sy0;
		int isy1 = cast(int) sy1;
		int ysh0 = cast(int) ((1.0 - std.math.modf(sy0, t0)) / h0h * 256 + 0.5);
		//int ysh1 = cast(int) (std.math.modf(sy1, t1) / h0h * 256);
		int kyarea = (isy1 - isy0 - 1) * ky;		
		if (ysh0 +  kyarea > 256)
			ysh0 = 256 - kyarea;
		int ysh1 = 256 - ysh0 - kyarea;
		assert(ysh0 >= 0);
		assert(ysh1 >= 0);
		assert(kyarea >= 0);
		assert(ysh0 + kyarea + ysh1 == 256);

		if (y==h-1) isy1 = isy0;

		void addRow(int rsi, int rk) {
			foreach(x; 0..w) {
				int si = rsi + aisx0[x] * 4;
				if (aisx1[x] > aisx0[x]) { // several pixels
					int r = org[si] * sh0[x];
					int g = org[si+1] * sh0[x];
					int b = org[si+2] * sh0[x];
					int sx = aisx0[x] + 1;
					while(sx < aisx1[x]) {
						si += 4;
						r += org[si] * kx;
						g += org[si+1] * kx;
						b += org[si+2] * kx;
						sx++;
					}
					si += 4;
					r += org[si] * sh1[x];
					g += org[si+1] * sh1[x];
					b += org[si+2] * sh1[x];
					row[x][0] += r * rk; row[x][1] += g * rk; row[x][2] += b * rk;
				} else { // just one pixel					
					row[x][0] += org[si] * rk;
					row[x][1] += org[si+1] * rk;
					row[x][2] += org[si+2] * rk;
				}
			} //for x
		} //addRow

		foreach(ref px; row) px[0..3] = 0;
		int rsi = isy0 * w0 * 4;

		if (isy1 > isy0) { // several rows
			addRow(rsi, ysh0);
			int sy = isy0 + 1;
			while(sy < isy1) {
				rsi += w0 * 4;
				addRow(rsi, ky);
				sy++;
			}
			rsi += w0 * 4;
			addRow(rsi, ysh1);
		} else { //one pixel row
			addRow(rsi, 256);
		}
		int di = y * w * 4;
		foreach(x; 0..w) {
			data[di] = cast(ubyte) (row[x][0] >> 16);
			data[di+1] = cast(ubyte) (row[x][1] >> 16);
			data[di+2] = cast(ubyte) (row[x][2] >> 16);
			di += 4;
		}
	}	
	version(verbose) auto dt = core.time.TickDuration.currSystemTick - tt0;
	version(verbose) writefln("resized in %s ms", dt.msecs);
	HBITMAP hbm = CreateCompatibleBitmap(Graphics.getScreen().handle, w, h);
	SetBitmapBits(hbm, data.length, data.ptr);
	delete data;
	delete orgbmp;
	return new shared(Bitmap)(hbm, true);
}

class Worker
{
	this(Tid improcTid)
	{
		iptid = improcTid;
	}

	void Run()
	{
		bool done = false;
		while(!done) 
			receive(&Work, (Exit e) { done = true; }, (OwnerTerminated ot) { done = true;} );		
	}

	private void Work(HaveWork msg)
	{
		auto job = LabourDept.dept.GetJob();
		if (job is null) return;
		auto jgt = cast(JGetThumb) job;
		if (jgt) { // GetThumb
			auto pic = ReadPicture(jgt.fname);			
			auto bmp = pic ? ResizeToThumb(pic) : cast(shared) RedPic();
			if (bmp)
				iptid.send(ThumbCreated(jgt.fname, bmp, jgt.req));			
			return;
		}
		auto jprep = cast(JPrepare) job;
		if (jprep) { //prepare: read and resize to blog size
			auto srcbmp = ReadBitmap(jprep.fname);
			auto turned = ImageProcessor.Rotate( srcbmp, jprep.angle );
			if (abs(jprep.fangle) > 0.0001) {
				auto rotated = ImageProcessor.FineRotate(turned, jprep.fangle);
				delete turned;
				turned = rotated;
			}
			auto bmp = ResizeForBlog(turned);
			if (bmp)
				iptid.send(Prepared(jprep.fname, bmp));			
			return;
		}
	}

private:
	Tid iptid;
}

struct Vec 
{
	int x, y;

	this(int X, int Y) pure { x = X; y = Y; }
	this(Point p) { x = p.x; y = p.y; }
	this(Size sz) { x = sz.width; y = sz.height; }

	Vec opSub(Vec v) pure { return Vec(x - v.x, y - v.y); }
	Vec opAdd(Vec v) pure { return Vec(x + v.x, y + v.y); }
	int mul(Vec v) pure { return x * v.y - y * v.x; }
}

bool InsideRect(Vec p, ref Vec[4] ps) pure
{
	int[4] s; //signs
	foreach(i; 0..4) {
		Vec to_p = p - ps[i];
		Vec to_next = ps[(i+1) & 3] - ps[i];
		s[i] = sgn( to_p.mul(to_next) );
	}
	return (s[0] == s[1] && s[2] == s[3] && s[1] == s[2]);		
}

class ImageProcessor
{
	static shared int maxOutX = 1200;
	static shared int maxOutY = 900;	

	Bitmap GetThumb(string fname)
	{
		req_no++;
		if (fname in thumb_cache) {
			Pic p = thumb_cache[fname]; 
			p.last_req = req_no;
			return p.bmp;
		}
		PostJob(new shared(JGetThumb)(fname, req_no));
		return null;
	}

	this(void delegate(string) gottmb)
	{
		onGotThumb = gottmb;
		jpgWriter = new JpegWriter;
	}

	void Start()
	{
		if (workers.length > 0) return;
		LabourDept.dept = new shared(LabourDept);
		picCache = new shared(PictureCache);
		auto strt = (Tid iptid) { with(new Worker(iptid)) Run(); };			
		foreach(i; 0..config.numWorkerThreads) {			
			Tid tid = spawnLinked(strt, thisTid);
			workers ~= tid;
		}		
		//time_reg = regex("[0-9: ]{19}");
		timer = new Timer;
		timer.interval = 100;
		timer.tick ~= &OnTimer;
		timer.start();
	}

	void PostJob(shared Job job)
	{
		LabourDept.dept.PostJob(job);
		foreach(w; workers)
			w.send(HaveWork());
	}

	void Stop()
	{
		LabourDept.quit = true;
		foreach(w; workers)
			w.send(Exit());
		while(terminated.length < workers.length)
			receive(&GotThumb, &LinkDied);
	}

	Image FileSelected(string prevFile, string curFile, string nextFile)
	{
		if (processed[1] && processed[1].fname == curFile) return processed[1].bmp; //already done
		requested[0] = prevFile; requested[1] = curFile; requested[2] = nextFile;
		Pic[3] pix;
		bool[3] used = [false, false, false];
		foreach(i; 0..3) {
			foreach(j; 0..3)
				if (processed[j] && processed[j].fname==requested[i]) {
					pix[i] = processed[j];
					used[j] = true;
					break;
				}
		}
		foreach(i; 0..3) {
			if (!used[i] && processed[i]) delete processed[i].bmp;
			processed[i] = pix[i];
		}
		int rot(string name) { return rotations.get(name, 0); }
		double frot(string name) { return fine_rotations.get(name, 0.0); }
		if (nextFile && processed[2] is null) PostJob(new shared(JPrepare)(nextFile, rot(nextFile), frot(nextFile)));
		if (prevFile && processed[0] is null) PostJob(new shared(JPrepare)(prevFile, rot(prevFile), frot(prevFile)));
		if (processed[1] is null) {	//prepare now
			auto turned = Prepare(curFile);
			auto bmp = ResizeForBlog( turned );
			processed[1] = new Pic(curFile, cast(Bitmap)bmp);			
		}
		return processed[1].bmp;
	}

	bool SaveCurrent(string fname, out string orgname)
	{
		if (processed[1] is null) return false;
		try {
			jpgWriter.Write(processed[1].bmp, fname);
		} catch(Exception ex) { //cannot create file 
			return false;
		}
		orgname = processed[1].fname;
		return true;
	}

	@property Bitmap current()
	{
		return processed[1] ? processed[1].bmp : null;
	}

	@property string curFile()
	{
		return processed[1] ? processed[1].fname : null;
	}


	bool TurnLeft()
	{
		return Turn90(1);		
	}

	bool TurnRight()
	{
		return Turn90(3);
	}

	bool FineRotation(double angle)
	{
		if (processed[1] is null || processed[1].bmp is null) return false;
		auto srcbmp = ReadBitmap(processed[1].fname);
		auto turned = ApplyRotation(srcbmp, processed[1].fname);
		if (processed[1].fname in fine_rotations) 
			angle += fine_rotations[processed[1].fname];
		fine_rotations[processed[1].fname] = angle;
		auto rotated = FineRotate(turned, angle);
		processed[1].ReplaceBmp( cast(Bitmap) ResizeForBlog(rotated) );
		return true;
	}

	static Bitmap Rotate(Bitmap srcbmp, int angle)
	{
		Bitmap turned;
		switch(angle & 3) {
			case 0: turned = srcbmp; break;
			case 1: turned = TurnBitmap!("x*w0 + w0-1-y")( srcbmp ); break;
			case 2: turned = TurnAround( srcbmp ); break; 
			case 3: turned = TurnBitmap!("(h0-1-x)*w0 + y")( srcbmp ); break;
			default:
		}		
		if (angle & 3) delete srcbmp;
		return turned;
	}

	Bitmap CropCurrent(double dx0, double dy0, double dx1, double dy1) // args in 0..1
	{
		if (processed[1] is null || processed[1].bmp is null) return null;
		auto sbmp = Prepare(processed[1].fname);
		int w0 = sbmp.width, h0 = sbmp.height;

		auto old = processed[1].cropped;
		if (old.length > 0) { 
			dx0 = old[0] + (old[2] - old[0]) * dx0;
			dy0 = old[1] + (old[3] - old[1]) * dy0;
			dx1 = old[0] + (old[2] - old[0]) * dx1;
			dy1 = old[1] + (old[3] - old[1]) * dy1;		
		}
		int x0 = cast(int)(dx0 * w0), y0 = cast(int)(dy0 * h0);
		int x1 = cast(int)(dx1 * w0), y1 = cast(int)(dy1 * h0);
		int w = x1 - x0, h = y1 - y0;
		int[] src, dst;
		src.length = w0 * h0;
		dst.length = w * h;
		GetBitmapBits(sbmp.handle, src.length*4, src.ptr);
		foreach(y; 0..h) {
			int si = (y + y0) * w0 + x0;
			int di = y * w;
			dst[di..di+w] = src[si..si+w];			
		}
		HBITMAP hbm = CreateCompatibleBitmap(Graphics.getScreen().handle, w, h);
		SetBitmapBits(hbm, dst.length*4, dst.ptr);
		auto bmp = new Bitmap(hbm, true);	
		auto rbmp = cast(Bitmap) ResizeForBlog(bmp);
		processed[1].ReplaceBmp(rbmp);
		processed[1].cropped = [dx0,dy0,dx1,dy1];
		delete src; delete dst;
		return rbmp;
	}

	string GetTimeStamp(string fname)
	{		
		char[] searchTime(char[] data) 
		{
			bool good(char c) { return (c>='0' && c<='9') || c==' ' || c==':'; }
			int i = 0, n = data.length;
			while(true) {
				while(i < n && !good(data[i])) i++;
				if (i >= n) return [];
				int j = i;
				while(j < n && good(data[j])) j++;
				if (j - i >= 19) return data[i..i+19];
				if (j >= n) return [];
				i = j;
			}		
		}

		if (fname in timestamps) return timestamps[fname];
		string res = "";
		try {
			auto data = cast(char[]) read(fname, 2048);
			auto t = searchTime(data);
			if (t.count!(std.ascii.isDigit)==14) {
				t[4] = '.'; t[7] = '.';
				res = "(" ~ t.idup ~ ")";
			}
		} catch(Exception ex) { }
		timestamps[fname] = res;
		return res;
	}

	bool AutoLevels()
	{
		if (processed[1] is null || processed[1].bmp is null) return false;
		int w = processed[1].bmp.width, h = processed[1].bmp.height;
		ubyte[] data;
		immutable sz = w * h * 4; 
		data.length = sz;
		auto res = GetBitmapBits(processed[1].bmp.handle, data.length, data.ptr);
		assert(res==sz);
		int mn = 255, mx = 0;//, i = 0;
		foreach(i; iota(0, sz, 4)) {
			foreach(c; data[i..i+3]) {
				if (c < mn) mn = c;
				if (c > mx) mx = c;
			}			
		}		
		if (mx <= mn || (mn==0 && mx==255)) return false;		
		ubyte[256] tab;
		foreach(x; mn..mx+1) 
			tab[x] = cast(ubyte) ((x - mn) * 255 / (mx-mn));		
		foreach(i; iota(0, sz, 4)) 
			foreach(ref x; data[i..i+3]) x = tab[x];		
		SetBitmapBits(processed[1].bmp.handle, sz, data.ptr);
		delete data;		
		return true;
	}

private:

	Bitmap Prepare(string fname) // read and rotate, do not resize yet
	{
		auto srcbmp = ReadBitmap(fname);
		auto turned = ApplyRotation(srcbmp, fname);
		if (fname in fine_rotations) {
			auto rotated = FineRotate(turned, fine_rotations[fname]);
			delete turned;
			turned = rotated;
		}
		return turned;
	}

	Bitmap ApplyRotation(Bitmap srcbmp, string fname)
	{
		if (fname !in rotations) return srcbmp;
		return Rotate( srcbmp, rotations[fname] );
	}

	bool Turn90(int angle_delta)
	{
		if (processed[1] is null || processed[1].bmp is null) return false;
		int angle = angle_delta;
		if (processed[1].fname in rotations)
			angle += rotations[processed[1].fname];		
		auto srcbmp = ReadBitmap(processed[1].fname);
		rotations[processed[1].fname] = angle;
		auto turned = ApplyRotation(srcbmp, processed[1].fname);
		processed[1].ReplaceBmp( cast(Bitmap) ResizeForBlog(turned) );
		return true;
	}

	static Bitmap TurnBitmap(alias coord_calc)(Bitmap bmp)
	{
		int[] src, dst;
		int w0 = bmp.width, h0 = bmp.height;
		int w = h0, h = w0;
		src.length = w * h;
		dst.length = w * h;
		GetBitmapBits(bmp.handle, src.length*4, src.ptr);
		foreach(y; 0..h) {
			int di = y * w;			
			foreach(x; 0..w)
				dst[di + x] = src[mixin(coord_calc)];
		}
		HBITMAP hbm = CreateCompatibleBitmap(Graphics.getScreen().handle, w, h);
		SetBitmapBits(hbm, dst.length*4, dst.ptr);
		delete src;
		delete dst;
		return new Bitmap(hbm, true);
	}

	static Bitmap TurnAround(Bitmap bmp)
	{
		int[] src, dst;
		int w = bmp.width, h = bmp.height;
		src.length = w * h;	dst.length = w * h;
		GetBitmapBits(bmp.handle, src.length*4, src.ptr);
		foreach(y; 0..h) {
			int di = y * w;			
			foreach(x; 0..w)
				dst[di + x] = src[(h-1-y)*w + w-1-x];
		}
		HBITMAP hbm = CreateCompatibleBitmap(Graphics.getScreen().handle, w, h);
		SetBitmapBits(hbm, dst.length*4, dst.ptr);
		delete src;
		delete dst;
		return new Bitmap(hbm, true);
	}

	static Bitmap FineRotate(Bitmap turned, double angle)
	{
		int w0 = turned.width, h0 = turned.height;
		int w2 = w0/2, h2 = h0/2; 		
		real x1 = w2 * cos(angle) - h2 * sin(angle);
		real y1 = w2 * sin(angle) + h2 * cos(angle);
		int ix = cast(int)x1;
		int iy = cast(int)y1;
		real x2, y2;
		version(verbose) auto tt0 = core.time.TickDuration.currSystemTick;		
		if (w0 >= h0) {
			x2 = -w2 * cos(angle) - h2 * sin(angle);
			y2 = -w2 * sin(angle) + h2 * cos(angle);
		} else {
			x2 = w2 * cos(angle) + h2 * sin(angle);
			y2 = w2 * sin(angle) - h2 * cos(angle);
		}
		int ix2 = cast(int)x2;
		int iy2 = cast(int)y2;

		int maxarea = 0, bx=0, by=0;
		Vec[4] rc = [Vec(ix,iy), Vec(ix2,iy2), Vec(-ix,-iy), Vec(-ix2, -iy2)];
		foreach(pt; 0..100) {
			int px = pt * ix / 100 + (100-pt) * ix2 / 100;
			int py = pt * iy / 100 + (100-pt) * iy2 / 100;
			bool inside = InsideRect(Vec(px, -py), rc);
			int area = abs(py) * abs(px);
			if (inside && area > maxarea) {
				maxarea = area;
				bx = px; by = py;
			}
		}
		bx = abs(bx); by = abs(by);
		int w = 2*bx, h = 2*by;
		int[] src, dst;		
		src.length = w0 * h0; dst.length = w * h;
		GetBitmapBits(turned.handle, src.length*4, src.ptr);
		void addrgb(ubyte* rgb, int kxy, ref int r, ref int g, ref int b)
		{
			r += rgb[0]*kxy;
			g += rgb[1]*kxy;
			b += rgb[2]*kxy;
		}
		immutable long unit = 1L << 24;
		foreach(y; 0..h) {
			int di = y * w;	
			long sx = cast(long)((-bx * cos(angle) - (-by + y) * sin(angle) + w2) * unit);
			long sy = cast(long)((-bx * sin(angle) + (-by + y) * cos(angle) + h2) * unit);
			long dx = cast(long)(cos(angle) * unit), dy = cast(long)(sin(angle) * unit);
			foreach(x; 0..w) {
				int isx = cast(int)(sx >> 24), isy = cast(int)(sy >> 24);
				if (isx < 0) isx = 0;
				if (isy < 0) isy = 0;
				if (isx < w0-1 && isy < h0-1) {					
					int kx = cast(int) ((sx >> 16) & 0xFFL);
					int ky = cast(int) ((sy >> 16) & 0xFFL);
					int r=0,g=0,b=0;
					int si = isy*w0 + isx;
					addrgb(cast(ubyte*) &src[si], (256-kx)*(256-ky), r,g,b);
					addrgb(cast(ubyte*) &src[si+1], kx*(256-ky), r,g,b);
					addrgb(cast(ubyte*) &src[si+w0], (256-kx)*ky, r,g,b);
					addrgb(cast(ubyte*) &src[si+w0+1], kx*ky, r,g,b);
					ubyte* rgb = cast(ubyte*) &dst[di + x];
					rgb[0] = cast(ubyte)(r >> 16);
					rgb[1] = cast(ubyte)(g >> 16);
					rgb[2] = cast(ubyte)(b >> 16);
				} else {
					isx = w0 - 1;				
					isy = h0 - 1;				
					dst[di + x] = src[isy*w0 + isx];
				}
				sx += dx; sy += dy;
			}
		}
		version(verbose) auto dt = core.time.TickDuration.currSystemTick - tt0;
		version(verbose) writefln("rotated in %s ms", dt.msecs);

		HBITMAP hbm = CreateCompatibleBitmap(Graphics.getScreen().handle, w, h);
		SetBitmapBits(hbm, dst.length*4, dst.ptr);
		delete src;
		delete dst;
		return new Bitmap(hbm, true);
	}

	void OnTimer(Timer sender, EventArgs ea)
	{
		while(receiveTimeout(dur!"msecs"(0), &GotThumb, &LinkDied, &GotResized)) {}
	}

	void GotThumb(ThumbCreated tb)
	{		
		thumb_cache[tb.fname] = new Pic(tb.fname, cast(Bitmap)tb.bmp, tb.req);
		if (thumb_cache.length > config.thumbCacheSize) {
			auto tbs = thumb_cache.byKey().map!(name => tuple(name, thumb_cache[name]));
			auto mp = tbs.minCount!((a,b) => a[1].last_req < b[1].last_req)[0];
			mp[1].dispose();
			thumb_cache.remove(mp[0]);
		}
		if (onGotThumb !is null) onGotThumb(tb.fname);
	}

	void LinkDied(LinkTerminated lt) 
	{ 
		terminated[lt.tid] = true; 
	}

	void GotResized(Prepared p)
	{
		foreach(i; [0,2]) {
			if (requested[i] == p.fname) {
				if (processed[i] && processed[i].bmp) delete processed[i].bmp;
				processed[i] = new Pic(p.fname, cast(Bitmap)p.bmp);
				return;
			}
		}
	}

	Pic[string] thumb_cache;
	int req_no = 0;
	Tid[] workers;
	Timer timer;
	void delegate(string) onGotThumb;
	bool[Tid] terminated;
	Pic[3] processed;
	string[3] requested;
	JpegWriter jpgWriter;
	int[string] rotations;
	double[string] fine_rotations;
	string[string] timestamps;
}
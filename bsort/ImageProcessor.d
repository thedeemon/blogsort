module imageprocessor;
import dfl.all, std.c.windows.windows, dfl.internal.winapi, std.concurrency, std.range, core.time, std.algorithm;
import std.typecons, jpg, std.stdio, std.traits;
import core.thread : Thread;

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

	this(string filename, Bitmap bitmap, int req = 0)
	{
		super(req, filename);  bmp = bitmap; 
	}

	void dispose() { if (bmp) delete bmp; }
	void dispose() shared { if (bmp) delete bmp; }
}

class CachedPicture : CachedImage
{
	Picture pic;

	this(string filename, Picture pict, int req = 0)
	{
		super(req, filename); pic = pict;
	}

	void dispose() { if (pic) pic.dispose(); }
	void dispose() shared { if (pic) { auto p = cast(Picture) pic; p.dispose(); } }
}

void AddToCache(T)(ref T[string] cache, string name, T val, int maxsize)
{
	cache[name] = val;
	if (cache.length > maxsize) {
		auto tbs = cache.byKey().map!(name => tuple(name, cache[name]));
		auto mp = tbs.minPos!((a,b) => a[1].last_req < b[1].last_req);
		mp.front[1].dispose();
		cache.remove(mp.front[0]);
	}
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
	string toString() const { return "GetThumb " ~ fname; }
}

class JPrepare : Job //read and resize to blogsize
{
	this(string filename) { super(Priority.Soon, filename); }
	string toString() const { return "Prepare " ~ fname; }
}

synchronized class LabourDept
{
	void PostJob(shared Job job)
	{
		auto j = cast(Job)job;
		writeln("PostJob: ", j);
		foreach(existing; jobs[job.prio]) {
			if (existing.fname == job.fname) {
				auto jgt = cast(JGetThumb) job;
				auto egt = cast(JGetThumb) existing;
				if (jgt && egt)
					egt.req = max(egt.req, jgt.req);
				writeln("already in queue");
				return;
			}
		}
		jobs[job.prio] ~= job;
		if (job.prio == Priority.Visible && jobs[job.prio].length > maxThumbJobs) {
			jobs[job.prio] = jobs[job.prio][$-maxThumbJobs..$];
		}
	}

	shared(Job) GetJob()
	{
		foreach(p; 0..4) {
			if (jobs[p].length > 0) {
				auto job = jobs[p][0];
				jobs[p] = jobs[p][1..$];
				auto j = cast(Job)job;
				writeln("run job ", j);
				return job;
			}
		}
		return null;
	}

	static shared LabourDept dept;

private:
	Job[][4] jobs; //4 priorities
	immutable maxThumbJobs = 8;
}

void limitSize(int w0, int h0, int maxX, int maxY, ref int w, ref int h)
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
		while(true) {
			bool loading = false;
			synchronized(this) {
				auto loaded = fname in pic_cache;
				if (loaded) return cast(Picture) pic_cache[fname].pic;
				loading = !!(fname in loading_pics);
			}
			if (loading) {
				Thread.sleep( dur!("msecs")(77) );
				continue;
			}
			return null; // not found at all
		}		
	}

	void Loaded(string name, Picture pic) shared
	{
		loading_pics.remove(name);
		pic_req_no++;		
		//AddToCache!(shared(CachedPicture))(pic_cache, name, new shared(CachedPicture)(name, pic, pic_req_no), 5);
		pic_cache[name] = new shared(CachedPicture)(name, pic, pic_req_no);
		if (pic_cache.length > 5) {
			auto tbs = pic_cache.byKey().map!(name => tuple(name, pic_cache[name]));
			auto mp = tbs.minPos!((a,b) => a[1].last_req < b[1].last_req);
			auto cp = cast(CachedPicture) mp.front[1];
			cp.dispose();
			pic_cache.remove(mp.front[0]);
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
			auto t0 = core.time.TickDuration.currSystemTick;
			auto p = new Picture(fname);
			auto dt = core.time.TickDuration.currSystemTick - t0;
			writefln("picture %s read in %s ms.", fname, dt.msecs);
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
	limitSize(w0, h0, 160, 120, w, h);
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
	auto r = GetBitmapBits(orgbmp.handle, org.length, org.ptr);
	assert(r==orgsz);

	limitSize(w0, h0, ImageProcessor.maxOutX, ImageProcessor.maxOutY, w, h);
	if (w>=w0 && h>=h0) 
		return cast(shared(Bitmap))orgbmp;

	ubyte[] data;
	data.length = w * h * 4;
	foreach(y; 0..h) {
		int di = y * w * 4;
		int sy = y * h0 / h;	
		foreach(x; 0..w) {
			int sx = x * w0 / w;
			int si = (sy * w0 + sx) * 4;
			data[di..di+3] = org[si..si+3];
			di += 4;
		}
	}	
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

	void run()
	{
		bool done = false;
		while(!done) 
			receive(&work, (Exit e) { done = true; }, (OwnerTerminated ot) { done = true;} );		
	}

	void work(HaveWork msg)
	{
		auto job = LabourDept.dept.GetJob();
		if (job is null) return;
		auto jgt = cast(JGetThumb) job;
		if (jgt) { // GetThumb
			shared(Bitmap) bmp;
			auto pic = ReadPicture(jgt.fname);
			if (pic) {
				bmp = ResizeToThumb(pic);
				//pic.dispose();
			} else 
				bmp = cast(shared) RedPic();
			if (bmp)
				iptid.send(ThumbCreated(jgt.fname, bmp, jgt.req));			
			return;
		}
		auto jprep = cast(JPrepare) job;
		if (jprep) { //prepare: read and resize to blog size
			auto bmp = ResizeForBlog(ReadBitmap(jprep.fname));
			if (bmp)
				iptid.send(Prepared(jprep.fname, bmp));			
			return;
		}
	}

private:
	Tid iptid;
}

void startWorker(Tid iptid)
{
	auto w = new Worker(iptid); 
	w.run();
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

	immutable NT = 4;

	this(void delegate(string) gottmb)
	{
		on_gotthumb = gottmb;
		jpgWriter = new JpegWriter;
	}

	void Start()
	{
		if (workers.length > 0) return;
		LabourDept.dept = new shared(LabourDept);
		picCache = new shared(PictureCache);
		foreach(i; 0..NT) {
			Tid tid = spawnLinked(&startWorker, thisTid);
			workers ~= tid;
		}		
		timer = new Timer;
		timer.interval = 100;
		timer.tick ~= &onTimer;
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
		foreach(w; workers)
			w.send(Exit());
		while(terminated.length < workers.length)
			receive(&gotThumb, &linkDied);
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
		if (nextFile && processed[2] is null) PostJob(new shared(JPrepare)(nextFile));
		if (prevFile && processed[0] is null) PostJob(new shared(JPrepare)(prevFile));
		if (processed[1] is null) {	//prepare now
			auto bmp = ResizeForBlog(ReadBitmap(curFile));
			processed[1] = new Pic(curFile, cast(Bitmap)bmp);
			return cast(Bitmap)bmp;
		}
		return processed[1].bmp;
	}

	bool SaveCurrent(string fname, out string orgname)
	{
		if (processed[1] is null) return false;
		jpgWriter.Write(processed[1].bmp, fname);
		orgname = processed[1].fname;
		return true;
	}

	@property Bitmap current()
	{
		return processed[1] ? processed[1].bmp : null;
	}

	bool Turn90(alias coord_calc)()
	{
		if (processed[1] is null || processed[1].bmp is null) return false;
		int[] src, dst;
		int w0 = processed[1].bmp.width, h0 = processed[1].bmp.height;
		int w = h0, h = w0;
		src.length = w * h;
		dst.length = w * h;
		GetBitmapBits(processed[1].bmp.handle, src.length*4, src.ptr);
		foreach(y; 0..h) {
			int di = y * w;			
			foreach(x; 0..w)
				dst[di + x] = src[mixin(coord_calc)];
		}
		HBITMAP hbm = CreateCompatibleBitmap(Graphics.getScreen().handle, w, h);
		SetBitmapBits(hbm, dst.length*4, dst.ptr);
		delete src;
		delete dst;
		delete processed[1].bmp;
		processed[1].bmp = new Bitmap(hbm, true);
		return true;
	}

	bool TurnLeft()
	{
		return Turn90!("x*w0 + w0-1-y");		
	}

	bool TurnRight()
	{
		return Turn90!("(h0-1-x)*w0 + y");
	}

private:
	void onTimer(Timer sender, EventArgs ea)
	{
		while(receiveTimeout(dur!"msecs"(0), &gotThumb, &linkDied, &gotResized)) {}
	}

	void gotThumb(ThumbCreated tb)
	{
		AddToCache(thumb_cache, tb.fname, new Pic(tb.fname, cast(Bitmap)tb.bmp, tb.req), max_thumbs);
		if (on_gotthumb !is null) on_gotthumb(tb.fname);
	}

	void linkDied(LinkTerminated lt) 
	{ 
		terminated[lt.tid] = true; 
	}

	void gotResized(Prepared p)
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
	immutable max_thumbs = 100;
	Tid[] workers;
	Timer timer;
	void delegate(string) on_gotthumb;
	bool[Tid] terminated;
	Pic[3] processed;
	string[3] requested;
	JpegWriter jpgWriter;
}
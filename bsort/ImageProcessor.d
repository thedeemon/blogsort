module imageprocessor;
import dfl.all, std.c.windows.windows, dfl.internal.winapi, std.concurrency, std.range, core.time, std.algorithm;
import std.typecons, jpg, std.stdio;

class Pic
{
	string fname;
	Bitmap bmp;
	int last_req;

	this(string filename, Bitmap bitmap, int req = 0)
	{
		fname = filename; bmp = bitmap; last_req = req;
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

Bitmap ReadPicture(string fname, int tries = 0)
{
	try {
		auto p = new Picture(fname);
		scope(exit) p.dispose();
		return p.toBitmap();
	} catch (DflException ex) { //failed
		if (tries < 3) {
			core.thread.Thread.sleep( dur!("msecs")(100) );
			return ReadPicture(fname, tries + 1);
		}
		return RedPic(100,100);
	}
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
			try {
				auto pic = new Picture(jgt.fname);
				scope(exit) pic.dispose();
				bmp = ResizeToThumb(pic);				
			} catch (DflException ex) {
				bmp = cast(shared) RedPic();
			}
			if (bmp)
				iptid.send(ThumbCreated(jgt.fname, bmp, jgt.req));			
			return;
		}
		auto jprep = cast(JPrepare) job;
		if (jprep) { //prepare: read and resize to blog size
			auto bmp = ResizeForBlog(ReadPicture(jprep.fname));
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
			auto bmp = ResizeForBlog(ReadPicture(curFile));
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
		thumb_cache[tb.fname] = new Pic(tb.fname, cast(Bitmap)tb.bmp, tb.req);
		if (thumb_cache.length > max_thumbs) {
			auto tbs = thumb_cache.byKey().map!(name => tuple(name, thumb_cache[name]));
			auto mp = tbs.minPos!((a,b) => a[1].last_req < b[1].last_req);
			delete mp.front[1].bmp;
			thumb_cache.remove(mp.front[0]);
		}
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
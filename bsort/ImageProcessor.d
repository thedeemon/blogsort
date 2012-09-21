module imageprocessor;
import dfl.all, std.c.windows.windows, dfl.internal.winapi, std.concurrency, std.range, core.time, std.algorithm;
import std.typecons;

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
struct ThumbCreated
{
	string fname;
	shared Bitmap bmp;	
	int req;
}

enum Priority {
	Immediate = 0, Soon = 1, Visible = 2, Background = 3
}

class Job 
{ 
	Priority prio; 
	this(Priority p) { prio = p; }
}

class JGetThumb : Job 
{
	string fname;
	int req;
	this(string filename, int req_no) { super(Priority.Visible); fname = filename; req = req_no; }
}

class JPrepare : Job //read and resize to blogsize
{
	string fname;
	this(string filename) { super(Priority.Soon); fname = filename; }
}

synchronized class LabourDept
{
	void PostJob(shared Job job)
	{
		jobs[job.prio] ~= job;
	}
	shared(Job) GetJob()
	{
		foreach(p; 0..4) {
			if (jobs[p].length > 0) {
				auto job = jobs[p][0];
				jobs[p] = jobs[p][1..$];
				return job;
			}
		}
		return null;
	}

	static shared LabourDept dept;

private:
	Job[][4] jobs; //4 priorities
}

class Worker
{
	this(Tid improcTid)
	{
		iptid = improcTid;
	}

	private shared(Bitmap) ResizeToThumb(Picture pic)
	{
		Graphics g = Graphics.getScreen();
		HDC memdc = CreateCompatibleDC(g.handle);
		if (memdc is null) return null;
		scope(exit) DeleteDC(memdc);
		int w0 = pic.width, h0 = pic.height;
		int w = 160;
		int h = h0 * w / w0;
		if (h > 120) {
			h = 120;
			w = w0 * h / h0;
		}

		HBITMAP hbm = CreateCompatibleBitmap(g.handle, w, h);
		if (hbm is null) return null;
		HGDIOBJ oldbm = SelectObject(memdc, hbm);
		pic.drawStretched(memdc, Rect(0,0, w,h));
		if(oldbm)
			SelectObject(memdc, oldbm);		
		return new shared(Bitmap)(hbm, true);
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
			auto pic = new Picture(jgt.fname);
			if (pic is null) return;
			auto bmp = ResizeToThumb(pic);
			pic.dispose();
			if (bmp)
				iptid.send(ThumbCreated(jgt.fname, bmp, jgt.req));			
			return;
		}
		auto jprep = cast(JPrepare) job;
		if (jprep) {
			//prepare: read and resize to blog size
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

	this(void delegate() gottmb)
	{
		on_gotthumb = gottmb;
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
		if (processed[2] is null) PostJob(new shared(JPrepare)(nextFile));
		if (processed[0] is null) PostJob(new shared(JPrepare)(prevFile));
		if (processed[1] is null) {
			//prepare now
			auto p = new Picture(curFile);
			auto bmp = p.toBitmap();
			processed[1] = new Pic(curFile, bmp);
			return bmp;
		}
		return processed[1].bmp;
	}

private:
	void onTimer(Timer sender, EventArgs ea)
	{
		while(receiveTimeout(dur!"msecs"(0), &gotThumb, &linkDied)) {}
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
		if (on_gotthumb !is null) on_gotthumb();
	}

	void linkDied(LinkTerminated lt) 
	{ 
		terminated[lt.tid] = true; 
	}

	Pic[string] thumb_cache;
	int req_no = 0;
	immutable max_thumbs = 100;
	Tid[] workers;
	Timer timer;
	void delegate() on_gotthumb;
	bool[Tid] terminated;
	Pic[3] processed;
	string[3] requested;
}
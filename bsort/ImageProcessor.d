module imageprocessor;
import dfl.all, std.c.windows.windows, dfl.internal.winapi, std.concurrency, std.range, core.time;

class Pic
{
	string fname;
	Bitmap bmp;
	int last_req;

	this(string filename, Bitmap bitmap)
	{
		fname = filename; bmp = bitmap; last_req = 0;
	}
}

// messages
struct HaveWork { } 
struct Exit {}
struct ThumbCreated
{
	string fname;
	shared Bitmap bmp;	
}

enum Priority {
	Immediate = 0, Soon = 1, Visible = 2, Background = 3
}

class Job 
{ 
	Priority prio; 
}

class JGetThumb : Job 
{
	string fname;
	this(string filename) {	fname = filename; prio = Priority.Visible;	}
}

synchronized class LabourDept
{
	static shared LabourDept dept;
	//shared static this() { dept = new shared(LabourDept); }	

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
				iptid.send(ThumbCreated(jgt.fname, bmp));
				//thumb_cache[fname] = new Pic(fname, bmp);			
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
		if (fname in thumb_cache) 
			return thumb_cache[fname].bmp;
		PostJob(new shared(JGetThumb)(fname));
		/*auto pic = new Picture(fname);
		if (pic is null) return null;
		Bitmap bmp = ResizeToThumb(pic);
		if (bmp)
			thumb_cache[fname] = new Pic(fname, bmp);
		pic.dispose();
		return bmp;*/
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

private:
	void onTimer(Timer sender, EventArgs ea)
	{
		while(receiveTimeout(dur!"msecs"(0), &gotThumb, &linkDied)) {}
	}

	void gotThumb(ThumbCreated tb)
	{
		thumb_cache[tb.fname] = new Pic(tb.fname, cast(Bitmap)tb.bmp);
		if (on_gotthumb !is null) on_gotthumb();
	}

	void linkDied(LinkTerminated lt) 
	{ 
		terminated[lt.tid] = true; 
	}

	Pic[string] thumb_cache;
	Tid[] workers;
	Timer timer;
	void delegate() on_gotthumb;
	bool[Tid] terminated;
}
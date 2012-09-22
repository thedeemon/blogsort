module jpg;
import dfl.all, std.c.windows.windows, std.stdio;

version(unittest) {	import std.traits; }

extern(Windows) { 
	LONG GetBitmapBits(
					   HBITMAP hbmp,      // handle to bitmap
					   LONG cbBuffer,     // number of bytes to copy
					   LPVOID lpvBits     // buffer to receive bits
					   );
}

alias uint JDIMENSION;
alias ubyte JSAMPLE;
alias JSAMPLE* JSAMPROW;
alias JSAMPROW* JSAMPARRAY;

enum J_COLOR_SPACE : int {
	JCS_UNKNOWN = 0,		/* error/unspecified */
	JCS_GRAYSCALE = 1,		/* monochrome */
	JCS_RGB = 2,		/* red/green/blue */
	JCS_YCbCr = 3,		/* Y/Cb/Cr (also known as YUV) */
	JCS_CMYK = 4,		/* C/M/Y/K */
	JCS_YCCK = 5		/* Y/Cb/Cr/K */
};

struct jpeg_error_mgr {
	int[33] _stuff;
}

struct jpeg_compress_struct 
{
	jpeg_error_mgr *err;
	int[6] _stuff1;
	JDIMENSION image_width;	/* input image width */
	JDIMENSION image_height;	/* input image height */
	int input_components;		/* # of color components in input image */
	J_COLOR_SPACE in_color_space;	/* colorspace of input image */
	int[93] _stuff2;
}

alias jpeg_compress_struct* j_compress_ptr;
alias ubyte boolean;
enum TRUE = 1;

extern(C) {
	jpeg_error_mgr* jpeg_std_error(jpeg_error_mgr * err);
	void jpeg_CreateCompress(jpeg_compress_struct* cinfo, int _version, uint structsize);
	void jpeg_stdio_dest(j_compress_ptr cinfo, void* outfile);
	void jpeg_set_defaults(j_compress_ptr cinfo);
	void jpeg_start_compress(j_compress_ptr cinfo, boolean write_all_tables);
	void jpeg_set_quality(j_compress_ptr cinfo, int quality, boolean force_baseline);
	JDIMENSION jpeg_write_scanlines(j_compress_ptr cinfo, JSAMPARRAY scanlines, JDIMENSION num_lines);
	void jpeg_finish_compress(j_compress_ptr cinfo);
	void jpeg_destroy_compress(j_compress_ptr cinfo);
}

class JpegWriter 
{
	this()
	{
		cinfo.err = jpeg_std_error(&err);
		jpeg_CreateCompress(&cinfo, 80, jpeg_compress_struct.sizeof);
	}

	~this()
	{
		jpeg_destroy_compress(&cinfo);
	}

	void Write(Bitmap bmp, string fname, int quality = 84)
	{
		auto f = File(fname, "wb");
		jpeg_stdio_dest(&cinfo, cast(void*)f.getFP());
		int h = bmp.height >= 0 ? bmp.height : -bmp.height;
		int w = bmp.width;
		cinfo.image_width = w; 
		cinfo.image_height = h;
		cinfo.input_components = 3;	
		cinfo.in_color_space = J_COLOR_SPACE.JCS_RGB;
		jpeg_set_defaults(&cinfo);
		jpeg_set_quality(&cinfo, quality, TRUE);
		jpeg_start_compress(&cinfo, TRUE);

		ubyte[] row, data;
		row.length = w * 3;
		int sz = w * h * 4;
		data.length = sz;
		ubyte* prow = row.ptr;
		auto r = GetBitmapBits(bmp.handle, sz, data.ptr);
		assert(r==sz);
		foreach(y; 0..h) {
			int si = y * w * 4;
			int di = 0;
			foreach(x; 0..w) { // RGB32 to RGB24
				row[di] = data[si+2];
				row[di+1] = data[si+1];
				row[di+2] = data[si];
				di += 3; si += 4;
			}
			jpeg_write_scanlines(&cinfo, &prow, 1);			
		}
		jpeg_finish_compress(&cinfo);
		f.close();
	}
	
private:
	jpeg_compress_struct cinfo;
	jpeg_error_mgr err;
}

unittest {
	writeln("testing jpg sz=", jpeg_compress_struct.sizeof);
	assert(jpeg_compress_struct.sizeof == 416);
	assert(jpeg_error_mgr.sizeof == 132);
	jpeg_compress_struct s;
	foreach(fld; __traits(allMembers, jpeg_compress_struct))
        writeln(fld, ": ", __traits(getMember, s, fld).offsetof);

	jpeg_compress_struct cinfo;
	jpeg_error_mgr err;
	cinfo.err = jpeg_std_error(&err);
	jpeg_CreateCompress(&cinfo, 80, jpeg_compress_struct.sizeof);
	writeln(cinfo.err);

	auto f = File("out.jpg", "wb");
	jpeg_stdio_dest(&cinfo, cast(void*)f.getFP());
	cinfo.image_width = 1280; 	/* image width and height, in pixels */
	cinfo.image_height = 1024;
	cinfo.input_components = 3;	/* # of color components per pixel */
	cinfo.in_color_space = J_COLOR_SPACE.JCS_RGB; /* colorspace of input image */
	jpeg_set_defaults(&cinfo);
	jpeg_set_quality(&cinfo, 84, 1);
	jpeg_start_compress(&cinfo, TRUE);

	ubyte[] row;
	row.length = 1280 * 3;
	ubyte* prow = row.ptr;
	foreach(y; 0..1024) {
		row[y*3] = 255;
		jpeg_write_scanlines(&cinfo, &prow, 1);
	}

	jpeg_finish_compress(&cinfo);
	f.close();

	jpeg_destroy_compress(&cinfo);
}

module winmain;
import core.runtime, std.c.windows.windows, dfl.application, bsform;
version(verbose) import std.stdio;

extern (Windows)
int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    int result;

    void exceptionHandler(Throwable e)
    {
        throw e;
    }

    try   {
        Runtime.initialize(&exceptionHandler);
        result = myWinMain(hInstance, hPrevInstance, lpCmdLine, nCmdShow);		
        Runtime.terminate(/*&exceptionHandler*/null);
    }  catch (Throwable o)	{	// catch any uncaught exceptions    
		version(verbose) writeln(o, o.file, o.line, o.info);
        MessageBoxA(null, cast(char *)o.toString(), "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;		// failed
    }

    return result;
}

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	Application.enableVisualStyles();
	version(unittest) { return 0; }
	Application.run(new MainForm());
    return 0;
}

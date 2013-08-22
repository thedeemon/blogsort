## BlogSort

A simple Windows app for viewing photos and preparing them for a blog: rotate, crop, resize and save as jpeg. Reads and prepares pictures in background, so stepping to next or previous photo takes 0 seconds. Automatically selects output size for a picture, given max values. Automatically advances output file names, like cat01.jpg -> cat02.jpg -> cat03.jpg... 

![screenshot][1]

### Usage:
Use left mouse button to select area for cropping. Use right button to pick two points of a horizon, then press "Horizon" to rotate the image to make those points lie on one horizontal line. 

Keys:

  - L - turn 90° left
  - R - turn 90° right
  - H - fine rotate to make horizon marks lie on one horizontal line
  - C - crop to selected area
  - Esc - clear selection and horizon marks
  - A - auto levels (normalise brightness)
  - + - make image brighter
  - - - make image darker
  - Z - switch zoom between "fit 100%" and "1:1 output" scales
  - G - save current picture

### Technical details
Written in D language. Built using DMD 2.062. Uses DFL for GUI, take it from https://github.com/Rayerd/dfl (only needed for compiling, the binary blogsort.exe does not need any additional dlls). Uses libjpeg for writing.

DFL (C) 2004-2010 Christopher E. Miller

IJG JPEG library (C) 1994-2011, Thomas G. Lane, Guido Vollbeding.

### License
Copyright (C) 2012-2013 Dmitry Popov, Infognition Co. Ltd.

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights 
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[1]: https://bitbucket.org/infognition/bsort/downloads/blogsort-screenshot600.jpg
## BlogSort

A simple Windows app for viewing photos and preparing them for a blog: rotate, crop, resize and save as jpeg. Reads and prepares pictures in background, so stepping to next or previous photo takes 0 seconds. Automatically selects output size for a picture, given max values. Automatically advances output file names, like cat01.jpg -> cat02.jpg -> cat03.jpg... 

![screenshot][1]

### Usage:
Use left mouse button to select area for cropping. Use right button to pick two points of a horizon, then press "Line up" to rotate the image to make those points lie on one horizontal line. 

Keys:

  - L - turn 90° left
  - R - turn 90° right
  - H - fine rotate to make horizon marks lie on one horizontal line
  - C - crop to selected area
  - Esc - clear selection and horizon marks
  - A - auto levels (fix brightness)
  - Z - switch zoom between "fit 100%" and "1:1 output" scales
  - G - save current picture

### Technical details
Written in D language. Built using DMD 2.060. Uses DFL for GUI, take it from https://github.com/Rayerd/dfl (only needed for compiling, the binary blogsort.exe does not need any additional dlls). Uses libjpeg for writing.

### Copyrights
BlogSort (C) 2012 Dmitry Popov a.k.a. Dee Mon. License: MIT

DFL (C) 2004-2010 Christopher E. Miller

IJG JPEG library (C) 1994-2011, Thomas G. Lane, Guido Vollbeding.

[1]: https://bitbucket.org/infognition/bsort/downloads/blogsort-screenshot600.jpg
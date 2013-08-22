                             Usage
=================================================
Select an image by pressing Browse button. 
Images from that folder will be displayed as thumbnails on the left.
You can use keyboard up/down arrows to iterate over images or just use
your mouse.

When some image is selected and displayed in the main window
the following operations are available:

* Turn 90 degrees left or right by clicking buttons L or R in the window
or pressing L or R on keyboard.

* Line up horizon: select two points on the image by clicking them with right
mouse button. Then press H on keyboard or click "Horizon" button in the window.
The image will be rotated so the two selected points will become on one
horizontal line.

* Crop: select image part using left mouse button, then press C keyboard
button or "Crop" window button.

You can clear current horizon marks and cropping rectangle by pressing ESC.

* Auto Levels: press keyboard button A or "AutoLevel" window button to 
normalize image brightness.

* Gamma correction: press +/- to make image brighter/darker.

* Zoom: by pressing Z keyboard button or "Zoom" window button you can switch
between showing whole image (resized to fit) or showing just central part of
it but with 1:1 scale (using target size).

* Save: press G on keyboard (meaning "go" or "good") or "Save" window button
to save current image to a file which name is set in "Out:" textbox.
If your file name ends with digits, the program will automatically increase
the number after saving, making a new file name. For example, after saving
file named "photo03.jpg" the textbox will change to "photo04.jpg" which can
be used for saving the next photo. This way you don't need to specify names
for each file, just set a name once for a set of images.
Your image will be automatically resized so that its width and height fit into
the limits set in "max size:" boxes on the top right of the window.
Aspect ratio will be preserved, you don't need to specify different resolutions
for landscape and portrait photos, just set maximum width and height for both.
Images are saved to JPG format.

In the left window thumbnails of saved images are marked with green border.

* You can undo your last operation (rotate, crop or autolevel) by pressing
"Undo" window button. By pressing "Undo all" you cancel all transformations
and get the original image. 



                         Source code
=================================================
This program is open source. You can find its source code at
https://bitbucket.org/infognition/bsort

It's written in D programming language.

Libraries used:

DFL (C) 2004-2010 Christopher E. Miller

IJG JPEG library (C) 1994-2011, Thomas G. Lane, Guido Vollbeding.


                           License
=================================================
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


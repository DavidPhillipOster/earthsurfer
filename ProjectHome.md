**EarthSurfer** - A Macintosh OS X application to use a Nintendo Wii Balance Board ![http://earthsurfer.googlecode.com/git/html/images/earthsurfer.png](http://earthsurfer.googlecode.com/git/html/images/earthsurfer.png) to travel over Google Earth in a milk truck ![http://earthsurfer.googlecode.com/git/html/images/Remote.png](http://earthsurfer.googlecode.com/git/html/images/Remote.png).

# Download [EarthSurfer](http://earthsurfer.googlecode.com/git/downloads/EarthSurfer1.0.2.zip) #
**Download [EarthSurfer](http://earthsurfer.googlecode.com/git/downloads/EarthSurfer1.0.2.zip)**

## Compatibility ##
I've tested this version on Intel Macs with Bluetooth under OS X 10.8.

The [original version](http://earthsurfer.googlecode.com/git/downloads/EarthSurfer0.6.0.zip) was tested on Intel Macs with Bluetooth under OS X 10.4 and OS X 10.5. Earth Surfer is not yet compatible with PowerPC Macs (I'm still working on some Bluetooth issues.)

## Earth Surfer Introduction ##

For Macworld, 2009 I decided to create a program that allows people to "surf" any region on the Earth's surface using a [Nintendo Wii Balance Board](http://en.wikipedia.org/wiki/Wii_Balance_Board) and the [Google Earth API](http://code.google.com/apis/earth/).  To do this, I used the [Google Earth Browser Plug-in](http://code.google.com/apis/earth/documentation/) with a Javascript [API](http://code.google.com/apis/earth/).  The Wii Balance Board transmits the your movements to the **EarthSurfer** application using Bluetooth and allows you to maneuver a virtual milktruck by shifting your balance as if you were on a surfboard.

Check out [this link](http://google-latlong.blogspot.com/2009/01/flying-through-google-earth-at-macworld.html) for a video to see it in action.



While it's fun to use **EarthSurfer**, I really wrote it to inspire others to consider interesting device interactions.  All my code is open source using the [Apache License](http://www.apache.org/licenses/LICENSE-2.0.html), so you can use the code in your own programs.



It is based on Thatcher Ulrich's terrific [open source](http://code.google.com/p/earth-api-samples/source/browse/trunk#trunk/demos/milktruck) Javascript [Monster Milktruck](http://earth-api-samples.googlecode.com/svn/trunk/demos/milktruck/index.html) [demo](http://code.google.com/apis/earth/documentation/demogallery.html), and runs in a webpage. I wrapped it as a Macintosh application program so I could add Objective-C.  Earth Surfer uses the Macintosh OS X Bluetooth framework to fetch the Bluetooth packets from the Wii Balance Board. I wrote methods to decode those packets into kilograms. I based my work on [DarwiinRemote](http://sourceforge.net/projects/darwiin-remote/), open source decoders for the [Wii Remote](http://en.wikipedia.org/wiki/Wii_Remote).

**EarthSurferHowTo** -
  * How to Install
  * How to Play

and for developers:
  * How to Build from source code
  * How to modify the source code, and
  * How you can help make this better.

**Hardware Requirements:**
  * an Apple Macintosh with a network connection and Bluetooth, running OS X 10.4 or newer. (Tested with OS X 10.8)
  * a Nintendo Wii Balance Board

You don't need the rest of the Wii for this. Just the Balance Board.


Note: Earth Surfer is more of a technology demo than a real, full-featured Macintosh application, so don't judge me harshly, just take the pieces and build something better.

## Related Work ##
I’m not the only one to go beyond the keyboard and mouse to control Google Earth. Some [related work](http://earthsurfer.googlecode.com/svn/html/references.html).

![http://earthsurfer.googlecode.com/svn/html/images/screenshot.jpg](http://earthsurfer.googlecode.com/svn/html/images/screenshot.jpg)
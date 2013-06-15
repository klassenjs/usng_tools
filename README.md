Introduction:
=============

Usng_tools consists of libraries in various languages to make supporting the
USNG (United States National Grid) and by association the MGRS easier.  It
supports converting to and from USNG/MGRS and Latitude/Longitude (additionally
UTM and UPS conversions are supported in the appropriate zones.)

Support for the 4 UPS zones (A,B,Y & Z) near the poles requires the [Proj4js
library](http://trac.osgeo.org/proj4js/).  Support for the 60 UTM zones is
provided by a built in UTM library.

On conversion to USNG, the coordinates are produced based on the specified
precision of the input.

On conversion to Lat/Lon from USNG, there is support for truncated coordinates
(leaving out the grid zone or the grid zone and the 100km grid square
designation).  The ambiguity is resolved by finding the closest valid
coordinate to a specified Lat/Lon.  Also, there is support for locating
coordinates in extended grid zones where the extension doesn't create any
ambiguity.

History:
--------

Usng_tools started in April 2008 as a GeoMOOSE extension to support USNG
coordinates.  It was re-written and released as a separate library on GitHub in
2009 to help support the Sahana foundations' Haiti Earthquake relief effort.

In 2013, it was extended to work in the southern hemisphere and near the poles.

References:
-----------

The USNG reference page can be found at: http://www.fgdc.gov/usng

Other references used:

- FGDC-STD-011-2001: http://www.fgdc.gov/standards/projects/FGDC-standards-projects/usng/fgdc_std_011_2001_usng.pdf
- MGRS specification: http://earth-info.nga.mil/GandG/publications/tm8358.1/tr83581b.html
- MGRS Zones A,B,Y,Z 100km grids: http://earth-info.nga.mil/GandG/coordsys/grids/universal_grid_system.html


Usage:
======

```html
<script src="proj4js-compressed.js"/>
<script src="usng2.js"/>
```

```javascript
u = new USNG2();

//
// Conversions from USNG to Lat/Lon
//

console.log(u.toLonLat( "18S UJ 228 070" ));
// Returns Object {lon: -77.04324684425941, lat: 38.8940174428622, precision: 3}

console.log(u.toLonLat( "UJ 228 070", {lon: -77, lat: 39} ));
// Returns Object {lon: -77.04324684425941, lat: 38.8940174428622, precision: 3}

console.log(u.toLonLat( "228 070", {lon: -77, lat: 39} ));
// Returns Object {lon: -77.04324684425941, lat: 38.8940174428622, precision: 3}

console.log(u.toLonLat( "B AN" ));
// Returns Object {lon: 0, lat: -90, precision: 0}

console.log(u.toLonLat( "Y ZP 12345 12345" ));
// Returns Object {lon: -171.85365493260602, lat: 84.43254784831868, precision: 5}

//
// Conversions from Lat/Lon to USNG
//

console.log(u.fromLonLat( { lon: -77.043, lat: 38.894 }, 3 ));
// Returns "18S UJ 228 069"

console.log(u.fromLonLat( { lon: -77.043, lat: 38.894 }, 5 ));
// Returns "18S UJ 22821 06997"
```

License:
========

Usng_tools is licensed under a MIT style license to encourage broad adoption.

License Text:
-------------

Copyright (c) 2008-2013 James Klassen

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the “Software”), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies of this Software or works derived from this Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.



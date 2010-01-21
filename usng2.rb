## Library to convert between NAD83 Lat/Lon and US National Grid
## Based on the FGDC-STS-011-2001 spec at http://www.fgdc.gov/standards/projects/FGDC-standards-projects/usng/fgdc_std_011_2001_usng.pdf
## Also based on the UTM library already in GeoMOOSE
## (c) Jim Klassen 4/2008
## Not tested in southern hemisphere...
## Known to fail for USNG zones A and B

#
# License:
# 
# Copyright (c) 2008-2009 James Klassen
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies of this Software or works derived from this Software.
# 
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#

class USNG2
	class LL84
		attr_reader :lon, :lat

		def initialize(lon, lat)
			@lon = lon.to_f
			@lat = lat.to_f
		end
	end

	class UTM
		attr_reader :utm_zone, :easting, :northing, :precision

	private
		MajorAxis = 6378137.0
		MinorAxis = 6356752.3
		Ecc = (MajorAxis * MajorAxis - MinorAxis * MinorAxis) / (MajorAxis * MajorAxis)
		Ecc2 = Ecc / (1.0 - Ecc)
		K0 = 0.9996
		E4 = Ecc * Ecc
		E6 = Ecc * E4
		Degrees2Radians = Math::PI / 180.0
		
		# Computes the meridian distance for the GRS-80 Spheroid.
		# See equation 3-22, USGS Professional Paper 1395.
		def self.meridianDist(lat) 
			c1 = MajorAxis * (1 - Ecc / 4 - 3 * E4 / 64 - 5 * E6 / 256)
			c2 = -MajorAxis * (3 * Ecc / 8 + 3 * E4 / 32 + 45 * E6 / 1024)
			c3 = MajorAxis * (15 * E4 / 256 + 45 * E6 / 1024)
			c4 = -MajorAxis * 35 * E6 / 3072
			
			return(c1 * lat + c2 * Math.sin(lat * 2) + c3 * Math.sin(lat * 4) + c4 * Math.sin(lat * 6))
		end

	public
		def initialize(utm_zone, easting, northing, precision)
			@utm_zone = utm_zone.to_i
			@easting = easting.to_f
			@northing = northing.to_f
			@precision = precision.to_i
		end

		def to_ll84
			zone = @utm_zone
			easting = @easting
			northing = @northing

			centeralMeridian = -((30 - zone) * 6 + 3) * Degrees2Radians
			
			temp1 = Math.sqrt(1.0 - Ecc)
			ecc1 = (1.0 - temp1) / (1.0 + temp1)
			ecc12 = ecc1 * ecc1
			ecc13 = ecc1 * ecc12
			ecc14 = ecc12 * ecc12
			
			easting = easting - 500000.0
			
			m = northing / K0
			um = m / (MajorAxis * (1.0 - (Ecc / 4.0) - 3.0 * (E4 / 64.0) - 5.0 * (E6 / 256.0)))
			
			temp8 = (1.5 * ecc1) - (27.0 / 32.0) * ecc13
			temp9 = ((21.0 / 16.0) * ecc12) - ((55.0 / 32.0) * ecc14)

			latrad1 = um + temp8 * Math.sin(2 * um) + temp9 * Math.sin(4 * um) + (151.0 * ecc13 / 96.0) * Math.sin(6.0 * um)
			
			latsin1 = Math.sin(latrad1)
			latcos1 = Math.cos(latrad1)
			lattan1 = latsin1 / latcos1
			n1 = MajorAxis / Math.sqrt(1.0 - Ecc * latsin1 * latsin1)
			t2 = lattan1 * lattan1
			c1 = Ecc2 * latcos1 * latcos1
			
			temp20 = (1.0 - Ecc * latsin1 * latsin1)
			r1 = MajorAxis * (1.0 - Ecc) / Math.sqrt(temp20 * temp20 * temp20)
			
			d1 = easting / (n1*K0)
			d2 = d1 * d1
			d3 = d1 * d2
			d4 = d2 * d2
			d5 = d1 * d4
			d6 = d3 * d3
			
			t12 = t2 * t2
			c12 = c1 * c1
			
			temp1 = n1 * lattan1 / r1
			temp2 = 5.0 + 3.0 * t2 + 10.0 * c1 - 4.0 * c12 - 9.0 * Ecc2
			temp4 = 61.0 + 90.0 * t2 + 298.0 * c1 + 45.0 * t12 - 252.0 * Ecc2 - 3.0 * c12
			temp5 = (1.0 + 2.0 * t2 + c1) * d3 / 6.0
			temp6 = 5.0 - 2.0 * c1 + 28.0 * t2 - 3.0 * c12 + 8.0 * Ecc2 + 24.0 * t12

			lat = (latrad1 - temp1 * (d2 / 2.0 - temp2 * (d4 / 24.0) + temp4 * d6 / 720.0)) * 180 / Math::PI
			lon = (centeralMeridian + (d1 - temp5 + temp6 * d5 / 120.0) / latcos1) * 180 / Math::PI
			
			return LL84.new(lon, lat)
		end

		# Convert lat/lon (given in decimal degrees) to UTM, and optionally given a particular UTM zone.
		def self.from_ll84(ll84, zone = nil)
			in_lon = ll84.lon.to_f
			in_lat = ll84.lat.to_f

			# Calculate UTM Zone number from Longitude
			# -180 = 180W is grid 1... increment every 6 degrees going east
			# Note [-180, -174) is in grid 1, [-174,-168) is 2, [174, 180) is 60 
			zone ||= ((in_lon - (-180.0)) / 6.0).floor + 1

			centeralMeridian = -((30 - zone) * 6 + 3) * Degrees2Radians
			
			lat = in_lat * Degrees2Radians
			lon = in_lon * Degrees2Radians
			
			latSin = Math.sin(lat)
			latCos = Math.cos(lat)
			latTan = latSin / latCos
			latTan2 = latTan * latTan
			latTan4 = latTan2 * latTan2
			
			n = MajorAxis / Math.sqrt(1 - Ecc * (latSin*latSin))
			c = Ecc2 * latCos*latCos
			a = latCos * (lon - centeralMeridian)
			m = meridianDist(lat)
			
			temp5 = 1.0 - latTan2 + c
			temp6 = 5.0 - 18.0 * latTan2 + latTan4 + 72.0 * c - 58.0 * Ecc2
			temp11 = (a**5)
		
			x = K0 * n * (a + (temp5 * (a**3)) / 6.0 + temp6 * temp11 / 120.0) + 500000
			
			temp7 = (5.0 - latTan2 + 9.0 * c + 4.0 * (c*c)) * (a**4) / 24.0
			temp8 = 61.0 - 58.0 * latTan2 + latTan4 + 600.0 * c - 330.0 * Ecc2
			temp9 = temp11 * a / 720.0
			
			y = K0 * (m + n * latTan * ((a * a) / 2.0 + temp7 + temp8 * temp9))
				
			return UTM.new(zone, x, y, 6) # TODO: made up precision
		end
	end

	class USNG
		attr_reader :utm_zone, :grid_zone, :grid_square
		attr_reader :easting, :northing, :precision

 	private
		# Note: grid locations are the SW corner of the grid square (because easting and northing are always positive)
		#                   0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19   x 100,000m northing
		NSLetters135 = ['A','B','C','D','E','F','G','H','J','K','L','M','N','P','Q','R','S','T','U','V']
		NSLetters246 = ['F','G','H','J','K','L','M','N','P','Q','R','S','T','U','V','A','B','C','D','E']
	
		#                  1   2   3   4   5   6   7   8   x 100,000m easting
		EWLetters14 = ['A','B','C','D','E','F','G','H']
		EWLetters25 = ['J','K','L','M','N','P','Q','R']
		EWLetters36 = ['S','T','U','V','W','X','Y','Z']
	
		#                  -80  -72  -64  -56  -48  -40  -32  -24  -16  -08   0    8   16   24   32   40   48   56   64   72   (*Latitude) 
		GridZones    = ['C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X']
		GridZonesDeg = [-80, -72, -64, -56, -48, -40, -32, -24, -16, -8 ,  0,   8,  16,  24,  32,  40,  48,  58,  64,  72]
	
		# TODO: This is approximate and actually depends on longitude too.
		GridZonesNorthing = Array.new(20) { |i|	
			110946.259 * GridZonesDeg[i] # == 2 * PI * 6356752.3 * (latitude / 360.0)
		}
		# = [-8875700.72, -7988130.648, -7100560.576, -6212990.504, -5325420.432, -4437850.36, -3550280.288, -2662710.216, -1775140.144, -887570.072, 0.0, 887570.072, 1775140.144, 2662710.216, 3550280.288, 4437850.36, 5325420.432, 6434883.022, 7100560.576, 7988130.648]

		# http://en.wikipedia.org/wiki/Great-circle_distance
		# http://en.wikipedia.org/wiki/Vincenty%27s_formulae 
		def llDistance(ll_start, ll_end)
			lat_s = ll_start.lat * Math.PI / 180
			lat_f = ll_end.lat * Math.PI / 180
			d_lon = (ll_end.lon - ll_start.lon) * Math.PI / 180
			return( Math.atan2( Math.sqrt( (Math.cos(lat_f) * Math.sin(d_lon)**2) + (Math.cos(lat_s)*Math.sin(lat_f) - Math.sin(lat_s)*Math.cos(lat_f)*Math.cos(d_lon)**2)) ,
					Math.sin(lat_s)*Math.sin(lat_f) + Math.cos(lat_s)*Math.cos(lat_f)*Math.cos(d_lon) )
				);
		end


	 public
		def self.parse_usng(usng)
			# Parse USNG into component parts
			easting = 0;
			northing = 0;
			precision = 0;

			digits = nil # don't really need this if using call to parsed...
			grid_square = nil
			grid_zone = nil
			utm_zone = nil
			
			# Make sure uppercase and remove whitespace (shouldn't be any)
			usng = usng.upcase.gsub(/ /, "")

			# Strip Coordinate values off of end, if any
			# This will be any trailing digits.
			re = Regexp.compile("([0-9]+)$")
			fields = re.match(usng)
			if(fields) then
				digits = fields[0]
				precision = digits.length / 2 # TODO: throw an error if #digits is odd.
				easting = (digits.slice(0, precision))
				northing =(digits.slice(precision, precision))
			end
			usng = usng.slice(0, usng.length-(precision*2))

			# Get 100km Grid Designator, if any
			re = Regexp.compile("([A-Z][A-Z]$)")
			fields = re.match(usng)
			if(fields) then
				grid_square = fields[0]
			end
			usng = usng.slice(0, usng.length - 2)

			# Get UTM and Grid Zone
			re = Regexp.compile("([0-9]+)([A-Z])")
			fields = re.match(usng)
			if(fields) then
				utm_zone = fields[1]
				grid_zone = fields[2]
			end

			USNG.new(utm_zone, grid_zone, grid_square, easting, northing, precision)
		end

 		# Returns a USNG String for a UTM point, and zone id's, and precision
		# utm_zone => 15 
		# utm_easting => 491000, utm_northing => 49786000; precision => 2 (digits)
		def self.from_utm(utm)
			utm_zone = utm.utm_zone
			utm_easting = utm.easting
			utm_northing = utm.northing
			precision = utm.precision
	
			# Calculate USNG Grid Zone Designation from Latitude
			# Starts at -80 degrees and is in 8 degree increments
			lat = utm.to_ll84.lat	
			if(! ((lat > -80) && (lat < 80) )) then
				throw("USNG2: Latitude must be between -80 and 80. (Zones A and B are not implemented yet.)")
			end
			grid_zone = GridZones[((lat - (-80.0)) / 8).floor] 			

			# Check valid coordinate
			raise("USNG2: Invalid UTM Zone") unless (0..60).include?(utm_zone.to_i)
			raise("USNG2: Invalid Easting") unless (100000..9000000).include?(utm_easting)
			raise("USNG2: Invalid Northing") unless (0..10000000).include?(utm_northing)
		
			grid_square_set = utm_zone % 6;
			
			ew_idx = (utm_easting / 100000).floor - 1          # should be [100000, 9000000]
			ns_idx = ((utm_northing % 2000000) / 100000).floor # should [0, 10000000) => [0, 2000000)
			grid_square = case(grid_square_set)
				when 1; EWLetters14[ew_idx] + NSLetters135[ns_idx]
				when 2; EWLetters25[ew_idx] + NSLetters246[ns_idx]
				when 3; EWLetters36[ew_idx] + NSLetters135[ns_idx]
				when 4; EWLetters14[ew_idx] + NSLetters246[ns_idx]
				when 5; EWLetters25[ew_idx] + NSLetters135[ns_idx]
				when 0; EWLetters36[ew_idx] + NSLetters246[ns_idx] # Calculates as zero, but is technically 6
			end
		
			# Calc Easting and Northing integer to 100,000s place
			easting  = (utm_easting % 100000).floor.to_s
			northing = (utm_northing % 100000).floor.to_s

			# Pad up to meter precision (5 digits)
			while(easting.length < 5) do
				easting = '0' + easting
			end
			while(northing.length < 5) do
				northing = '0' + northing
			end
		
			if(precision > 5) then
				# Calculate the fractional meter parts
				digits = precision - 5
				grid_easting  = easting + ("%#{digits}f" % (utm_easting % 1)).slice(2,digits)
				grid_northing = northing + ("%#{digits}f" % (utm_northing % 1)).slice(2,digits)
			else
				# Remove unnecessary digits
				grid_easting  = easting.slice(0, precision)
				grid_northing = northing.slice(0, precision)
			end
			return USNG.new(utm_zone, grid_zone, grid_square, grid_easting, grid_northing, precision)	
		end

		# Should really only be called by self.parse_usng and self.from_utm
		# UTM Zone Number (15), Grid Zone ('T'), 100km Grid Square ('VK'), easting (meters), northing (meters), 
		#  precision (significant digits per easting/northing) 
		def initialize(utm_zone, grid_zone, grid_square, easting, northing, precision)
			@utm_zone = utm_zone.to_i
			@grid_zone = grid_zone.to_s
			@grid_square = grid_square.to_s
			@easting = easting.to_s
			@northing = northing.to_s
			@precision = precision.to_i
		end

		def to_s
			return @utm_zone.to_s + @grid_zone + @grid_square + @easting + @northing
		end

		def to_utm
			utm_easting = 0
			utm_northing = 0

			grid_square_set = @utm_zone % 6
			ns_grid = nil
			ew_grid = nil
			case(grid_square_set)
				when 1 then
					ns_grid = NSLetters135
					ew_grid = EWLetters14
				when 2 then
					ns_grid = NSLetters246
					ew_grid = EWLetters25
				when 3 then
					ns_grid = NSLetters135
					ew_grid = EWLetters36
				when 4 then
					ns_grid = NSLetters246
					ew_grid = EWLetters14
				when 5 then
					ns_grid = NSLetters135
					ew_grid = EWLetters25
				when 0 then # grid_square_set will == 0, but it is technically group 6 
					ns_grid = NSLetters246
					ew_grid = EWLetters36
				else
					raise("USNG2: shouldn't get here")
			end
			ew_idx = ew_grid.find_index(grid_square[0])
			ns_idx = ns_grid.find_index(grid_square[1])
		
			if(ew_idx.nil? || ns_idx.nil?) then
				raise("USNG2: Invalid USNG 100km grid designator.")
			end
		
			scale_factor = 10**(5 - precision) # 1 digit => 10k place, 2 digits => 1k ...
			easting = @easting.to_f * scale_factor
			northing = @northing.to_f * scale_factor

			utm_easting = ((ew_idx + 1) * 100000) + easting # Should be [100000, 9000000]
			utm_northing = ((ns_idx + 0) * 100000) + northing # Should be [0, 2000000)
	
			# TODO: this really depends on easting too...
			# At this point know UTM zone, Grid Zone (min latitude), and easting
			# Right now this is lookup table returns a max number based on lon == utm zone center 	
			min_northing = GridZonesNorthing[GridZones.find_index(grid_zone)] # Unwrap northing to ~ [0, 10000000]
p min_northing
			utm_northing += 2000000 * ((min_northing - utm_northing) / 2000000).ceil

			# Check that the coordinate is within the utm zone and grid zone specified:
			utm = UTM.new(utm_zone, utm_easting, utm_northing, precision)
			ll = utm.to_ll84
			ll_utm_zone = ((ll.lon - (-180.0)) / 6.0).floor + 1
			ll_grid_zone = GridZones[((ll.lat - (-80.0)) / 8).floor]
			
			# If error from the above TODO mattered... then need to move north a grid
			if( ll_grid_zone != grid_zone) then
				utm_northing -= 2000000
				utm = UTM.new(utm_zone, utm_easting, utm_northing, precision)
				ll = utm.to_ll84
				ll_utm_zone = ((ll.lon - (-180.0)) / 6.0).floor + 1
				ll_grid_zone = GridZones[((ll.lat - (-80.0)) / 8).floor]
			end

			if(ll_utm_zone != utm_zone || ll_grid_zone != grid_zone) then
#				raise("USNG2: calculated coordinate not in correct UTM or grid zone! Supplied: "+utm_zone.to_s+grid_zone+" Calculated: "+ll_utm_zone.to_s+ll_grid_zone)
#				print("USNG2: calculated coordinate not in correct UTM or grid zone! Supplied: "+utm_zone.to_s+grid_zone+" Calculated: "+ll_utm_zone.to_s+ll_grid_zone)
			end

			return utm
		end # to_utm Method

		# Returns the bounding box of the USNG square represented by the coordinate
		# In the CS of the USNG coordinate (even if part of the square's extent
		# Happens to fall outside the 100km grid square/grid zone)
		def simple_bbox
			utm = self.to_utm
			size = 10**(5-@precision)

			minx = utm.easting
			miny = utm.northing

			maxx = minx + size
			maxy = miny + size

			srid=26900 + @utm_zone
			# ex. POLYGON((654000 5191000,654000 5192000,655000 5192000,655000 5191000,654000 5191000))
			"SRID=#{srid};POLYGON((#{minx} #{miny}, #{minx} #{maxy}, #{maxx} #{maxy}, #{maxx} #{miny}, #{minx} #{miny}))"
		end
	end # USNG Class
end # USNG2 Module


copy (select dataownercode AS agency_id, dataownername AS agency_name, 'http://'||dataownername||'.nl/' AS agency_url, 'Europe/Amsterdam' AS agency_timezone, 'nl' AS agency_lang FROM dataowner WHERE dataownercode <> 'ALGEMEEN') TO '/tmp/agency.txt' WITH CSV HEADER;

copy (select 'openOV' as feed_publisher_name, 'http://openov.nl/' as feed_publisher_url, 'nl' as feed_lang, replace(cast(min(operationdate) AS text), '-', '') as feed_start_date, replace(cast(max(operationdate) AS text), '-', '') as feed_end_date, now() as feed_version from localservicegroupvalidity) TO '/tmp/feed_info.txt' WITH CSV HEADER;

copy (select dataownercode||'_'||localservicelevelcode as service_id, replace(cast(operationdate as text), '-', '') as date, '1' as exception_type from localservicegroupvalidity) TO '/tmp/calendar_dates.txt' WITH CSV HEADER;

copy (select dataownercode||'_'||lineplanningnumber as route_id, dataownercode as agency_id, linepublicnumber as route_short_name, linename as route_long_name, g.route_type as route_type from line as l, gtfs_route_type as g where l.transporttype = g.transporttype) TO '/tmp/routes.txt' WITH CSV HEADER;

copy (select stop_id, stop_name, CAST(X(the_geom) AS NUMERIC(8,2)) AS stop_lon, CAST(Y(the_geom) AS NUMERIC(9,3)) AS stop_lat FROM (select distinct t.timingpointcode as stop_id, t.timingpointname as stop_name, ST_Transform(setsrid(makepoint(locationx_ew, locationy_ns), 28992), 4326) AS the_geom from timingpoint as t, usertimingpoint as u where u.timingpointcode = t.timingpointcode and u.userstopcode in (select distinct userstopcode from localservicegrouppasstime)) AS X) TO '/tmp/stops.txt' WITH CSV HEADER;

copy (select l.dataownercode||'_'||lineplanningnumber as route_id, l.dataownercode||'_'||l.localservicelevelcode as service_id, l.dataownercode||'_'||lineplanningnumber||'_'||l.localservicelevelcode||'_'||journeynumber||'_'||fortifyordernumber as trip_id, destinationname50 as trip_headsign, (linedirection - 1) as direction_id from localservicegrouppasstime as l, destination as d, (select distinct dataownercode, localservicelevelcode from localservicegroupvalidity) as v where l.dataownercode = d.dataownercode and l.destinationcode = d.destinationcode and l.userstopordernumber = 1 and v.dataownercode = l.dataownercode and v.localservicelevelcode = l.localservicelevelcode) TO '/tmp/trips.txt' WITH CSV HEADER;

start transaction; update localservicegrouppasstime set targetdeparturetime = targetarrivaltime where targetdeparturetime = '00:00:00' AND journeystoptype = 'LAST';
copy (select l.dataownercode||'_'||lineplanningnumber||'_'||l.localservicelevelcode||'_'||journeynumber||'_'||fortifyordernumber as trip_id, targetarrivaltime as arrival_time, targetdeparturetime as departure_time, timingpointcode as stop_id, userstopordernumber as stop_sequence, destinationname50 as stop_headsign from localservicegrouppasstime as l, destination as d, usertimingpoint as u, (select distinct dataownercode, localservicelevelcode from localservicegroupvalidity) as v where l.dataownercode = d.dataownercode and l.destinationcode = d.destinationcode and l.dataownercode = u.dataownercode and l.userstopcode = u.userstopcode and v.dataownercode = l.dataownercode and v.localservicelevelcode = l.localservicelevelcode) TO '/tmp/stop_times.txt' WITH CSV HEADER; rollback;
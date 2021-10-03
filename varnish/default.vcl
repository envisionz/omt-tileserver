# VCL script for varnish 4

vcl 4.0;

import std;
import var;
import xkey;

backend tileserver {
  .host = "${tileserver_host}";
  .port = "${tileserver_port}";
}

backend postserve {
  .host = "${postserve_host}";
  .port = "${postserve_port}";
}

acl purgers {
  "${purge_host}";
  "localhost";
}

sub vcl_recv {
  if (req.method == "PURGE") {
    if (client.ip !~ purgers) {
        return (synth(403, "Forbidden"));
    }
    if (req.http.xkey) {
		  #set req.http.n-gone = xkey.purge(req.http.xkey);
		  set req.http.n-gone = xkey.softpurge(req.http.xkey);
		  return (synth(200, "Invalidated "+req.http.n-gone+" objects"));
	  } else {
		  return (purge);
	  }
  }

  # Block access to the tileserver-gl '/data' endpoint, since we're exposing
  # the original vector tileserver (postserve) instead
  if (req.url ~ "/data/{0,1}") {
    return (synth(404, "Not found"));
  }

  unset req.http.cookie;

  if (req.url ~ "/tiles/[0-9]+/[0-9]+/[0-9]+\.pbf") {
    set req.backend_hint = postserve;
  } else {
    set req.backend_hint = tileserver;
  }

  // Cache only tiles
  if (req.url ~ "/[0-9]+/[0-9]+/[0-9](@[0-9]x){0,1}+\.(webp|png|jpg|jpeg|pbf)") {
    return (hash);
  } else {
    return (pass);
  }
}

sub vcl_backend_response {
  var.set_int("max_z", std.integer(std.getenv("OMT_CACHE_ZOOM_MAX"), 18));
  
  // Remove all cookies
  unset beresp.http.set-cookie;
  unset beresp.http.cookie;

  set beresp.grace = 2m;
  set beresp.keep = 8m;

  // set cache key based on tile coordinate, so all variants can be purged at once
  // Also, provide minimal caching for high zoom levels
  if (bereq.url ~ "/[0-9]+/[0-9]+/[0-9]+(@[0-9]x){0,1}\.(webp|png|jpg|jpeg|pbf)") {
    var.set_int("curr_z", std.integer(regsub(bereq.url, "^.+/([0-9]+)/[0-9]+/[0-9]+(@[0-9]x){0,1}\.(webp|png|jpg|jpeg|pbf).*$", "\1"), 18));
    // High zoom level's won't be sent purge requests, so set a short ttl
    if (var.get_int("curr_z") > var.get_int("max_z")) {
      set beresp.ttl = 30m;
    } else {
      set beresp.http.xkey = regsub(bereq.url, "^.+/([0-9]+/[0-9]+/[0-9]+)\.(webp|png|jpg|jpeg|pbf).*$", "\1");
      set beresp.ttl = 4w;
    }
  }
}

sub vcl_hash {
  // Cache using only url as a hash.  
  // This means if a.tile/1/1/1/tile.png is accessed, b.tile/1/1/1/tile.png will also be fetch from cache
  // Note, don't hash quey params for tiles
  if (req.url ~ "/[0-9]+/[0-9]+/[0-9]+(@[0-9]x){0,1}\.(webp|png|jpg|jpeg|pbf)") {
    hash_data(regsub(req.url, "^(.+/[0-9]+/[0-9]+/[0-9]+(@[0-9]x){0,1}\.(webp|png|jpg|jpeg|pbf)).*$", "\1"));
  } else {
    hash_data(req.url);
  }
  return (lookup);
}